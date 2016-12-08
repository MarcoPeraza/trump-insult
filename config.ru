require './app.rb'

# Outputs stdout to heroku logs
$stdout.sync = true

run TrumpEndpoints.new
