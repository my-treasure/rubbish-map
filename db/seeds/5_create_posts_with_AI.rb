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
  "something related to a violent event",
  "a fight",
  "a doog pooping",
  "poop",
  "trash",
  "drugs",
  "drug dealing",
  "something disguting",
  "something random",
  "something kinky",
  "something creepy",
  "something about drugs",
  "something happening in a club",
  "something secret",
  "something funny",
  "something extrange",
  "something about a party",
  "something about a crime",
  "something about a demostration",
]

TOPIC2 = [
  "a fight",
  "a doog pooping",
  "drugs",
  "stupidity",
  "non-sense",
  "kink",
  "poop",
  "being high"
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

#open text prompt from file:
def open_prompt(filename)
  File.open(File.join(Rails.root, filename)).read
end

def select_prompt(filename, prompt_type)
  topic = TOPIC.sample
  topic2 = TOPIC2.sample
  where = WHEREIS.sample
  prompt_txt = open_prompt(filename)
  "#{prompt_txt} Create #{prompt_type} about #{topic} and #{topic2} #{where}. (maximun of 250 characters)"
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
  # replace = ["GPT", "BetterDAN", "AI", "stay in character", "Stay in character", "stay in character!", "Stay in character!"]
  # delimiters = [':', "AI", "GPT"]
  # response.dig("choices", 0, "message", "content").gsub(Regexp.union(replace), "").split(Regexp.union(delimiters)).last
  response.dig("choices", 0, "message", "content").split(":").last
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

def prompt_from_tweet(filename, ai_tweet)
  response =
    CLIENT.chat(
      parameters: {
        model: "gpt-3.5-turbo", # Required.
        messages: [{ role: "system", content: "#{filename} Generate a prompt for text-to-image model with no text or captions of the following expresion #{ai_tweet}" }], # Required
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
        size: "512x512",
        model: "image-alpha-001"
      }
    )
  response.dig("data", 0, "url")
end

def image_uploader(ai_image)
  Cloudinary::Uploader.upload ai_image, public_id: "post_seed/#{Digest::SHA256.hexdigest(ai_image)}"
end

def ai_post_generator
  prompt = select_prompt("db/seeds/prompt_text.txt", "tweet")
  puts "📝 selected prompt: #{prompt.split("Prompt:").last}"
  tweet = ai_tweet(prompt.split("Prompt:").last)
  puts "🤖 AI tweet: #{tweet}"
  sleep(2)
  description = ai_tweet_description(tweet)
  puts "🤖 AI description: #{description}"
  sleep(5)
  image_prompt = prompt_from_tweet("db/seeds/prompt_text.txt", tweet)
  puts "🖼️ prompt image: #{image_prompt}"
  image = ai_image(image_prompt)
  puts "📸 created Ai image"
  if !image or image_prompt.include?("I'm sorry")
    puts "🤖 AI failed to create image, skipping post"
    return
  else
    image_id = image_uploader(image)["public_id"]
    puts "Uploading image to cloudinary..."
    sleep(5)
    return tweet, description, image_id
  end
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
    tweet, description, image_id = ai_post_generator
    if image_id
      file = URI.open(Cloudinary::Utils.cloudinary_url(image_id, options = {}))
      sleep_time = rand(5..10)
    end
  else
    tweet = Faker::Lorem.sentence(word_count: 3)
    description = Faker::Lorem.paragraph(sentence_count: 2)
    image = POST_PICTURES["resources"].sample
    file = URI.open(image["url"])
    image_id = image["public_id"]
    sleep_time = 0
  end

  if image_id
    new_post = Post.create(
      title: tweet,
      body: description,
      user_id: User.all.sample.id,
      address: reverse_geocode.first.address,
      latitude: rand_latitude,
      longitude: rand_longitude,
      created_at: Faker::Date.between(from: '2022-01-01', to: '2023-05-10')
    )
    new_post.post_image.attach(io: file, filename: image_id, content_type: "image/png")

    puts "Created post, sleeping #{sleep_time} seconds...\n"
    # wait before next request
    sleep(sleep_time)
  else
    puts "No image created, skipping post"
  end
end
puts "Created #{Post.count} posts"
