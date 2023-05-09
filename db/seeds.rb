# Dir[File.join(Rails.root, "db", "seeds", "*.rb")].each do |seed|
#   puts "seeding - #{seed}. loading seeds, for real!"
#   load seed
# end

# questions = [
#   {
#     type: "list",
#     name: "size",
#     message: "Select a seed file to run:",
#     choices: Dir[File.join(Rails.root, "db", "seeds", "*.rb")]
#   }
# ]
require 'inquirer'

list_seeds = Dir[File.join(Rails.root, "db", "seeds", "*.rb")]

idx = Ask.list "Select a seed file to run:", list_seeds
puts "You selected: #{list_seeds[idx]}"

load list_seeds[idx]
