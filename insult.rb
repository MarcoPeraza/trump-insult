require 'sinatra'

post '/insult' do
  {
    response_type: "in_channel",
    text: "#{params[:text]} is the single biggest liar I have ever seen."
  }.to_json
end
