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
require 'digest'

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

puts "🧼 Cleaning database..."
User.destroy_all
Post.destroy_all

puts "connecting with openai."
CLIENT =
  OpenAI::Client.new(
    access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"),
    request_timeout: 240
  )

# topis for creating tweets
puts "🤖 connecting with openai."
CLIENT =
  OpenAI::Client.new(
    access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"),
    request_timeout: 240
  )

# topis for creating tweets
TOPIC = [
  "something trashy",
  "something artsy",
  "something related to a violent event",
  "a fight",
  "a demostration",
  "a doog pooping",
  "something disguting",
  "something involving drugs",
  "something about music",
  "something illegal",
  "something random",
  "some non-sense",
  "something weird",
  "something kinky",
  "something queer",
  "something creepy",
  "something happening in a club",
  "something about ACAB",
  "something about black_market",
  "something underground",
  "something secret",
  "something funny",
  "something extrange",
  "something about a party",
  "something about a concert",
  "something about a festival"
]

WHEREIS = [
  "in a park of Berlin",
  "in a home in Berlin",
  "when going to a club of Berlin",
  "in a street of Berlin",
  "in a water fountain of Berlin",
  "in a bus of Berlin",
  "in the S-bahn",
  "in the U-bahn"
]

def select_prompt
  topic = TOPIC.sample
  where = WHEREIS.sample
  ["tweet about #{topic}, #{where}", "a picture of #{topic}, #{where}"]
end

def ai_tweet(topic)
  response =
    CLIENT.chat(
      parameters: {
        model: "gpt-3.5-turbo", # Required.
        messages: [{ role: "system", content: topic }], # Required
        temperature: 0.7
      }
    )
  response.dig("choices", 0, "message", "content")
end

def ai_tweet_description(ai_tweet)
  response =
    CLIENT.completions(
      parameters: {
        model: "text-davinci-001", # Required.
        prompt: ai_tweet[0..-30],
        max_tokens: 15
      }
    )
  response["choices"].map { |c| c["text"] }[0]
end

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

puts "Creating Post..."
post = 0
10.times do
  puts post += 1
  rand_latitude = rand(52.4901..52.5130)
  rand_longitude = rand(13.3888..13.4449)
  reverse_geocode = Geocoder.search([rand_latitude, rand_longitude])
  prompt = select_prompt
  puts "selected prompt: #{prompt}"
  tweet = ai_tweet(prompt)
  puts "AI tweet: #{tweet}"
  description = ai_tweet_description(tweet)
  puts "AI description: #{description}"

  Post.create(
    title: tweet,
    body: description,
    user_id: User.all.sample.id,
    post_image: ALL_IMAGES["resources"].sample["secure_url"],
    address: reverse_geocode.first.address,
    latitude: rand_latitude,
    longitude: rand_longitude,
    created_at: Faker::Date.between(from: '2022-01-01', to: '2023-05-10')
  )

  # wait before next request
  sleep(15)
end

puts "Created #{Post.count} posts"
puts "Finished!"
