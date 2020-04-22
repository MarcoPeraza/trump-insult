require 'sinatra/base'
require 'json'
require 'httparty'

require './insults'

# Three environment variables are consulted:
#  ENV['SLACK_CLIENT_ID'],
#  ENV['SLACK_CLIENT_SECRET'],
#  ENV["SLACK_VERIFY_TOKEN"]

def random_pic_path
  File.join('pics', Dir.entries('public/pics').select { |f| f =~ /.*\.jpg/ }.sample)
end

class TrumpEndpoints < Sinatra::Application
  get '/oauth' do
    result = HTTParty.post('https://slack.com/api/oauth.access',
                           body: {
                             client_id: ENV['SLACK_CLIENT_ID'],
                             client_secret: ENV['SLACK_CLIENT_SECRET'],
                             code: params['code']
                           })

    status 200
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

    if !payload || payload['token'] != ENV["SLACK_VERIFY_TOKEN"]
      halt 403, "Incorrect slack token"
    end

    action_name, action_value = payload['actions'][0]['name'], payload['actions'][0]['value'] if payload['actions'] && payload['actions'][0]

    case payload['callback_id']
    when 'insult_callback'

      channel = if (payload['channel']['name'] != 'privategroup')
                  "\##{payload['channel']['name']}"
                else
                  "#{payload['team']['domain']} channel"
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
                          color: '#d83924',
                          mrkdwn_in: ['text']
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

    actions = InsultTemplates.keys.map { |k| { name: k, text: k, type: 'button', value: target } }

    HTTParty.post(params[:response_url],
                  body: {
                    attachments: [
                      {
                        fallback: 'Error: Your Slack client does not support the necessary features',
                        text: 'Choose a kind of insult',
                        callback_id: 'insult_callback',
                        actions: actions
                      }
                    ]
                  }.to_json,
                  headers: { 'Content-Type' => 'application/json' })
    status 200
  end

end
