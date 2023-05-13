require "json"
require "faker"
require "geocoder"
require "open-uri"
require 'httparty'


PROFILE_PICTURES = Cloudinary::Api.resources(type: "upload", max_results: 500, prefix: "profile_pictures/")
puts PROFILE_PICTURES["resources"].first

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
  photo_blob = PROFILE_PICTURES["resources"].sample
  file = URI.open(photo_blob["secure_url"])
  new_user = User.create!(
    email: Faker::Internet.email,
    user_name: Faker::Internet.username,
    password: Faker::Internet.password(min_length: 6),
    role: "seed",
    address: reverse_geocode.first.address,
    latitude: rand_latitude,
    longitude: rand_longitude
  )
  new_user.profile_picture.attach(io: file, filename: photo_blob["public_id"], content_type: "image/jpg")
end
puts "Created #{User.count} users"
