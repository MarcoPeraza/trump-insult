require 'sinatra'
require 'json'

post '/insult' do
  content_type :json
  { response_type: "in_channel", text: "#{params[:text]} is the single biggest liar I have ever seen." }.to_json
end
