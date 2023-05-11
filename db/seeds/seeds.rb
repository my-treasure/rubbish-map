# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require "open-uri"
require "json"
require "faker"
require "geocoder"
require "openai"

# upload images to cloudinary
require "cloudinary"
require "cloudinary/uploader"
require "cloudinary/utils"

Cloudinary.config do |config|
  config.cloud_name = ENV.fetch("CLOUDINARY_CLOUD_NAME")
  config.api_key = ENV.fetch("CLOUDINARY_API_KEY")
  config.api_secret = ENV.fetch("CLOUDINARY_API_SECRET")
  config.secure = true
end
# -------------------------------------------- #
# checks if the images in assets already exist in cloudinary
puts "💫 1. Starting seeds..."
ALL_IMAGES = Cloudinary::Api.resources(type: "upload", max_results: 500)

puts "📝 2. Renaming images..."
# correcting image names replace "-", "(", ")" with "_"
Dir.foreach(
  File.join(Rails.root, "app", "assets", "images", "post_seed")
) do |filename|
  next if [".", ".."].include?(filename) # skip current and parent directories

  new_filename = filename.gsub(/[()]/, "_") # replace ( or ) with _

  if new_filename != filename # if there was a change in the filename
    File.rename(
      File.join(Rails.root, "app", "assets", "images", "post_seed", filename),
      File.join(
        Rails.root,
        "app",
        "assets",
        "images",
        "post_seed",
        new_filename
      )
    ) # rename the file
    puts "Renamed #{filename} to #{new_filename}"
  end
end

puts "📤 3. Uploading images to cloudinary..."
# check if item exist in ALL_IMAGES
Dir.foreach(
  File.join(Rails.root, "app", "assets", "images", "post_seed")
) do |filename|
  next if [".", ".."].include?(filename)

  if ALL_IMAGES["resources"].any? { |image| image["public_id"] == filename }
    puts "#{filename} already exist in cloudinary"
  else
    puts "#{filename} uploaded to cloudinary"
    Cloudinary::Uploader.upload File.join(
      Rails.root,
      "app",
      "assets",
      "images",
      "post_seed",
      filename
    ), public_id: filename
  end
end

puts "🧼 4. Cleaning database..."
User.destroy_all
Post.destroy_all

puts "🤓 Creating users with devise..."
puts "how many users do you want to create?"
print "➡️"
n_users = gets.chomp.to_i
puts n_users
puts "creating #{n_users} users..."

n_users.times do
  rand_latitude = rand(52.4901..52.5130)
  rand_longitude = rand(13.3888..13.4449)
  reverse_geocode = Geocoder.search([rand_latitude, rand_longitude])
  User.create!(
    email: Faker::Internet.email,
    user_name: Faker::Internet.username,
    password: Faker::Internet.password(min_length: 6),
    role: "seed",
    address: reverse_geocode.first.address,
    latitude: rand_latitude,
    longitude: rand_longitude
  )
end
puts "Created #{User.count} users"

puts "📸 Creating Post..."
puts "how many posts do you want to create?"
print "➡️"
n_posts = gets.chomp.to_i
puts n_posts

puts "creating #{n_posts} posts..."
post = 0
n_posts.times do
  print post += 1
  rand_latitude = rand(52.4901..52.5130)
  rand_longitude = rand(13.3888..13.4449)
  reverse_geocode = Geocoder.search([rand_latitude, rand_longitude])
  photo_blob = ALL_IMAGES["resources"].sample
  file = URI.open(photo_blob["url"])

  new_post = Post.create(
    title: Faker::Lorem.sentence(word_count: 3),
    body: Faker::Lorem.paragraph(sentence_count: 2),
    user_id: User.all.sample.id,

    address: reverse_geocode.first.address,
    latitude: rand_latitude,
    longitude: rand_longitude,
    created_at: Faker::Date.between(from: '2022-01-01', to: '2023-05-10')
  )

  new_post.post_image.attach(io: file, filename: photo_blob["public_id"] , content_type: "image/png")
  new_post.save
  puts "Created post"
end

puts "Created #{Post.count} posts"
puts "Finished!"
