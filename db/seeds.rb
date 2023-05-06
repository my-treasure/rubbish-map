# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'open-uri'
require 'json'
require 'faker'
require 'geocoder'

puts "Cleaning database..."
User.destroy_all
Post.destroy_all

puts "Creating users with devise..."
15.times do
  User.create!(
    email: Faker::Internet.email,
    password: Faker::Internet.password(min_length: 6)
  )
end
puts "Created #{User.count} users"

puts "Creating Post..."
pages = %w[top_rated popular upcoming]
pages.each do |page|
  url = "http://tmdb.lewagon.com/movie/#{page}"
  response = URI.open(url).read
  data = JSON.parse(response)
  data["results"].each do |movie|
    rand_latitude = rand(52.4901..52.5130)
    rand_longitude = rand(13.3888..13.4449)
    reverse_geocode = Geocoder.search([rand_latitude, rand_longitude])
    Post.create(
      title: movie["title"],
      body: Faker::Cannabis.strain,
      user_id: User.all.sample.id,
      post_image: "https://image.tmdb.org/t/p/w500#{movie['poster_path']}",
      address: reverse_geocode.first.address,
      lat: rand_latitude,
      lng: rand_longitude
    )
    puts "Created post #{movie['title']}"
  end
end
puts "Created #{Post.count} posts"
puts "Finished!"
