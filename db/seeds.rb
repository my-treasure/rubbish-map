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

puts "Cleaning database..."
# Post.destroy_all

puts "Creating Post..."
pages = %w[top_rated popular upcoming]
pages.each do |page|
  url = "http://tmdb.lewagon.com/movie/#{page}"
  response = URI.open(url).read
  data = JSON.parse(response)
  data["results"].each do |movie|
    Post.create(
      title: movie["title"],
      body: Faker::Cannabis.strain,
      user_id: randint(1..100),
      post_image: "https://image.tmdb.org/t/p/w500#{movie['poster_path']}",
      location: movie["vote_average"]
    )
  end
end
puts "Finished!"
