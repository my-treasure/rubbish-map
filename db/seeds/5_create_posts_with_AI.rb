# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require "json"
require "faker"
require "geocoder"
require "open-uri"
require "openai"

require 'digest'

POST_PICTURES = Cloudinary::Api.resources(type: "upload", max_results: 500, prefix: "post_seed/")

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
  "something random",
  "some non-sense",
  "something weird",
  "something kinky",
  "something queer",
  "something creepy",
  "something happening in a club",
  "something about ACAB",
  "something about black_market",
  "something secret",
  "something funny",
  "something extrange",
  "something about a party",
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

def select_prompt()
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
        prompt: ai_tweet[0..-80],
        max_tokens: 200
      }
    )
  response["choices"].map { |c| c["text"] }[0]
end

def prompt_from_tweet(ai_tweet)
  response =
    CLIENT.chat(
      parameters: {
        model: "gpt-3.5-turbo", # Required.
        messages: [{ role: "system", content: "generate a prompt for openai dalle image generator from this tweet: #{ai_tweet}" }], # Required
        temperature: 0.7
      }
    )
  response.dig("choices", 0, "message", "content")
end

# Creating image with Ai and uploading to cloudinary
# https://github.com/alexrudall/ruby-openai
def ai_image(prompt_from_tweet)
  response =
    CLIENT.images.generate(
      parameters: {
        prompt: prompt_from_tweet,
        size: "256x256",
        model: "image-alpha-001"
      }
    )
  response.dig("data", 0, "url")
end

def image_uploader(ai_image)
  Cloudinary::Uploader.upload ai_image, public_id: "post_seed/#{Digest::SHA256.hexdigest(ai_image)}"
end

def ai_post_generator()
  prompt, prompt_image = select_prompt()
  puts "selected prompt: #{prompt}"
  tweet = ai_tweet(prompt)
  puts "AI tweet: #{tweet}"
  sleep(2)
  description = ai_tweet_description(tweet)
  puts "AI description: #{description}"
  sleep(5)
  prompt_image = prompt_from_tweet(tweet)
  puts "prompt image: #{prompt_image}"
  image = ai_image(prompt_image)
  puts "created Ai image"
  image_id = image_uploader(image)["public_id"]
  puts "Uploading image to cloudinary..."
  sleep(5)
  return tweet, description, image_id
end

puts "📸 Creating Post..."
puts "🧠 Do you wish to prompts and images with OpenAI: [y,No] (be careful, it costs money 💸)"
print "➡️"
set_ai = false
if gets.chomp.downcase == "y"
  set_ai = true
else
  set_ai = false
end

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

  if set_ai
    tweet, description, image_id = ai_post_generator()
  else
    tweet = Faker::Lorem.sentence(word_count: 3)
    description = Faker::Lorem.paragraph(sentence_count: 2)
    image_id = POST_PICTURES["resources"].sample["public_id"]
  end

  new_post = Post.create(
    title: tweet,
    body: description,
    user_id: User.all.sample.id,
    address: reverse_geocode.first.address,
    latitude: rand_latitude,
    longitude: rand_longitude,
    created_at: Faker::Date.between(from: '2022-01-01', to: '2023-05-10')
  )
  new_post.post_image.attach(io: URI.open(Cloudinary::Utils.cloudinary_url(image_id, options = {})), filename: image_id , content_type: "image/png")

  puts "Created post, sleeping 10 seconds...\n"
  # wait before next request
  sleep(10)
end

puts "Created #{Post.count} posts"
