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
require "openai"

puts "Cleaning database..."
User.destroy_all
Post.destroy_all

puts "connecting with openai."
CLIENT = OpenAI::Client.new(
  access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"),
  request_timeout: 240
)
puts CLIENT.completions(
  parameters: {
    model: "gpt-3.5-turbo",
    prompt: "I love Mondays!"
  }
)
# topis for creating tweets
def select_prompt
  topic = ['trashy', 'artsy', 'violent', 'disguting', 'about drugs', 'about music', 'illegal', 'about poop', 'intense', 'random', 'non-sense', 'delirious', 'weird', 'kinky', 'about clubing', 'about ACAB', 'about black_market', 'underground', 'secret', 'funny', 'extrange']
  "create tweet about something #{topic.sample}, in the city of Berlin"
end

def ai_tweet(topic)
  response = CLIENT.chat(
    parameters: {
      model: "gpt-3.5-turbo", # Required.
      messages: [{ role: "user", content: topic }], # Required
      temperature: 0.7
    }
  )
  response.dig("choices", 0, "message", "content")
end

def ai_tweet_description(ai_tweet)
  response = CLIENT.chat(
    parameters: {
      model: "gpt-3.5-turbo", # Required.
      messages: [{ role: "user", content: "create description about this #{ai_tweet}" }], # Required.
      temperature: 0.7
    }
  )
  response.dig("choices", 0, "message", "content")
end

puts "Creating users with devise..."
10.times do
  rand_latitude = rand(52.4901..52.5130)
  rand_longitude = rand(13.3888..13.4449)
  reverse_geocode = Geocoder.search([rand_latitude, rand_longitude])
  User.create!(
    email: Faker::Internet.email,
    user_name: Faker::Internet.username,
    password: Faker::Internet.password(min_length: 6),
    address: reverse_geocode.first.address,
    latitude: rand_latitude,
    longitude: rand_longitude
  )
end
puts "Created #{User.count} users"

puts "Creating Post..."
pages = %w[top_rated]
pages.each do |page|
  url = "http://tmdb.lewagon.com/movie/#{page}"
  response = URI.open(url).read
  data = JSON.parse(response)
  data["results"].each do |movie|
    rand_latitude = rand(52.4901..52.5130)
    rand_longitude = rand(13.3888..13.4449)
    reverse_geocode = Geocoder.search([rand_latitude, rand_longitude])
    tweet = ai_tweet(select_prompt)
    puts "selected prompt: #{select_prompt}"
    description = ai_tweet_description(tweet)

    Post.create(
      title: tweet,
      body: description,
      user_id: User.all.sample.id,
      post_image: "https://image.tmdb.org/t/p/w500#{movie['poster_path']}",
      address: reverse_geocode.first.address,
      latitude: rand_latitude,
      longitude: rand_longitude
    )
    puts "Created tweet: #{tweet}"
  end
end

puts "Created #{Post.count} posts"
puts "Finished!"
