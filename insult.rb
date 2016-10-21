require 'sinatra'

post '/insult' do
  "#{params[:text]} is the single biggest liar I have ever seen."
end
