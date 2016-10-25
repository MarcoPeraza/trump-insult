require 'sinatra'
require 'sinatra/activerecord'
require './environments'
require 'json'
require 'httparty'

require './models'
require './insults'

get '/oauth' do
  result = HTTParty.post('https://slack.com/api/oauth.access',
                         body: {
                            client_id: ENV['SLACK_CLIENT_ID'],
                            client_secret: ENV['SLACK_CLIENT_SECRET'],
                            code: params['code']
                         })

  user = User.find_or_create_by(user_id: result['user_id'],
                                team_id: result['team_id'])
  user.access_token = result['access_token']
  user.scope = result['scope']
  user.save

  bot = Bot.find_or_create_by(user_id: result['bot']['bot_user_id'],
                              team_id: result['team_id'])
  bot.access_token = result['bot']['bot_access_token']
  bot.scope = result['scope']
  bot.save
end

get '/authorize' do
  redirect "https://slack.com/oauth/authorize?client_id=#{ENV['SLACK_CLIENT_ID']}&scope=channels:history channels:write channels:read files:read files:write:user groups:history groups:read groups:write users:read bot commands"
end

post '/event' do
  request.body.rewind
  raw_body = request.body.read
  data = JSON.parse(raw_body)

  if data['token'] != ENV['SLACK_VERIFY_TOKEN']
    halt 403, 'Incorrect slack token'
  end

  case data['type']
  when 'url_verification'
    content_type :json
    return {challenge: data['challenge']}.to_json
  end

  return 200
end

post '/interact' do

end

post '/insult' do
  if params[:ssl_check] == '1'
    halt 200
  end

  if params[:token] != ENV["SLACK_VERIFY_TOKEN"]
    halt 403, "Incorrect slack token"
  end

  channel = (params[:channel_name] != 'privategroup') ? "\##{params[:channel_name]}" : "#{params[:team_domain]} channel"

  insult = insult_templates.sample % { target: params[:text],
                                       channel: channel,
                                       caller: params[:user_name] }

  pic_url = url(File.join('pics',
                          Dir.entries('public/pics').select { |f| f =~ /.*\.jpg/ }.sample))

  HTTParty.post(params[:response_url],
                body: {
                        attachments: [
                          {
                            fallback: 'Error: Your Slack client does not support the necessary features',
                            text: 'Choose a kind of insult',
                            color: '#d83924',
                            actions: [
                              {
                                name: 'weak',
                                text: 'Weak',
                                type: 'button',
                                value: 'weak'
                              },
                              {
                                name: 'loser',
                                text: 'Loser',
                                type: 'button',
                                value: 'loser'
                              }
                            ]
                          }
                        ]
                      }.to_json,
                headers: { 'Content-Type' => 'application/json' })
  status 200
end
