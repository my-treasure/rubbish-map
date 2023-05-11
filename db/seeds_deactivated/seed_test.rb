require 'openai'
require 'cloudinary'

CLOUD_NAME = ENV.fetch("CLOUDINARY_CLOUD_NAME")
CLOUDINARY_URL = "https://api.cloudinary.com/v1_1/#{CLOUD_NAME}/image/upload/"

puts "🤖 connecting with openai."
CLIENT =
  OpenAI::Client.new(
    access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"),
    request_timeout: 240
  )


prompt = 'Draw a cute cat'

# generate image with OpenAI and upload to Cloudinary
def ai_image(prompt)
  response =
    CLIENT.images.generate(
      parameters: {
        prompt: prompt,
        size: "256x256",
        model: "image-alpha-001"
      }
    )
  response.dig("data", 0, "url")
end

ai_image = ai_image(prompt)
puts "🤖 AI image generated: #{ai_image}"
