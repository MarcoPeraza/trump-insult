require 'sinatra'
require 'json'
require 'httparty'

insult_templates = [
  "%{target}, such a dishonest person.",
  "%{target} suffers from BAD JUDGEMENT.",
  "%{target} has been failing for 30 years",
  "%{target}, not getting the job done.",
  "%{target} has failed all over the world.",
  "%{target} doesn't have the strength or the stamina to MAKE AMERICA GREAT AGAIN!.",
  "%{target}'s brainpower is highly overrated, decision making is so bad.",
  "%{target} is all talk and NO ACTION",
  "%{target} just wants to shut down and go home to bed",
  "%{target} has no energy left.",
  "%{target}, very sad!",
  "%{target} is a low energy individual",
  "%{target} gave up and enlisted Mommy and his brother",
  "%{target} is a pathetic figure!",
  "%{target} had to bring mommy to take a slap at me",
  "%{target}, he's bottom (and gone), I'm top (by a lot).",
  "%{target} is really pathetic.",
  "%{target} is mathematically dead and totally desperate.",
  "%{target}, I will sue him just for fun",
  "%{target} should be forced to take an IQ test",
  "Little %{target}, pathetic!",
  "%{target} only makes bad deals!",
  "%{target} is unattractive both inside and out. I fully understand why her former husband left her for a man- he made a good decision.",
  "Just heard that crazy and very dumb %{target} had a mental breakdown while talking about me on the low ratings %{channel}. What a mess!"
]

post '/event' do
  request.body.rewind

  raw_body = request.body.read
  puts raw_body

  event = JSON.parse(raw_body)

  case event['type']
  when "url_verification"
    content_type :json
    return {challenge: event['challenge']}.to_json
  end

  return 200
end

post '/insult' do
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
                body: { response_type: "in_channel",
                        link_names: "1",
                        attachments: [
                          {
                            fallback: insult,
                            text: insult,
                            image_url: pic_url,
                            color: "#d83924"
                          }
                        ]
                      }.to_json,
                headers: { "Content-Type" => "application/json" })
  status 200
end
