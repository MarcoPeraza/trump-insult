require 'sinatra/base'
require 'sinatra/activerecord'
require 'json'
require 'httparty'

require './db'
require './insults'

def random_pic_path
  File.join('pics', Dir.entries('public/pics').select { |f| f =~ /.*\.jpg/ }.sample)
end

class TrumpEndpoints < Sinatra::Application
  register Sinatra::ActiveRecordExtension

  configure :development do
    set :database, 'sqlite3:db/dev.db'
    set :show_exceptions, true
  end

  configure :production do
    db = URI.parse(ENV['DATABASE_URL'] || 'postgres:///localhost/mydb')

    ActiveRecord::Base.establish_connection(
      :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
      :host     => db.host,
      :username => db.user,
      :password => db.password,
      :database => db.path[1..-1],
      :encoding => 'utf8'
    )
  end

  get '/oauth' do
    result = HTTParty.post('https://slack.com/api/oauth.access',
                          body: {
                              client_id: ENV['SLACK_CLIENT_ID'],
                              client_secret: ENV['SLACK_CLIENT_SECRET'],
                              code: params['code']
                          })

    puts result

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
    payload = JSON.parse(params[:payload])
    puts payload

    action_name, action_value = payload['actions'][0]['name'], payload['actions'][0]['value'] if payload['actions'] && payload['actions'][0]

    case payload['callback_id']
    when 'insult_callback'

      channel = if (payload['channel']['name'] != 'privategroup')
                  "\##{payload['channel']['name']}"
                else
                  "that #{payload['team']['domain']} channel"
                end

      insult = InsultTemplates[action_name].sample % { target: action_value,
                                                      channel: channel,
                                                      caller: payload['user']['name'] }

      HTTParty.post(payload['response_url'],
                    body: {
                      delete_original: true,
                      response_type: "in_channel",
                      username: 'Donald J. Trump',
                      link_names: '1',
                      attachments: [
                        {
                          fallback: insult,
                          text: insult,
                          image_url: url(random_pic_path),
                          color: '#d83924'
                        }
                      ]
                    }.to_json,
                    headers: { 'Content-Type' => 'application/json' })
    end

    status 200
  end

  post '/insult' do
    if params[:ssl_check] == '1'
      halt 200
    end

    if params[:token] != ENV["SLACK_VERIFY_TOKEN"]
      halt 403, "Incorrect slack token"
    end

    target = params[:text]


    HTTParty.post(params[:response_url],
                  body: {
                          attachments: [
                            {
                              fallback: 'Error: Your Slack client does not support the necessary features',
                              text: 'Choose a kind of insult',
                              callback_id: 'insult_callback',
                              actions: [
                                {
                                  name: 'low_energy',
                                  text: 'Low Energy',
                                  type: 'button',
                                  value: target
                                },
                                {
                                  name: 'loser',
                                  text: 'Loser',
                                  type: 'button',
                                  value: target
                                },
                                {
                                  name: 'dishonest',
                                  text: 'Dishonest',
                                  type: 'button',
                                  value: target
                                },
                                {
                                  name: 'dumb',
                                  text: 'Very Dumb',
                                  type: 'button',
                                  value: target
                                }
                              ]
                            }
                          ]
                        }.to_json,
                  headers: { 'Content-Type' => 'application/json' })
    status 200
  end

end
