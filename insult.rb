require 'sinatra'
require 'json'
require 'httparty'

insults = [
  "%s, such a dishonest person.",
  "%s suffers from BAD JUDGEMENT.",
  "%s has been failing for 30 years",
  "%s, not getting the job done.",
  "%s has failed all over the world.",
  "%s doesn't have the strength or the stamina to MAKE AMERICA GREAT AGAIN!.",
  "%s's brainpower is highly overrated, decision making is so bad.",
  "%s is all talk and NO ACTION",
  "%s just wants to shut down and go home to bed",
  "%s has no energy left.",
  "%s, very sad!",
  "%s is a low energy individual",
  "%s gave up and enlisted Mommy and his brother",
  "%s is a pathetic figure!",
  "%s had to bring mommy to take a slap at me",
  "%s, he's bottom (and gone), I'm top (by a lot).",
  "%s is really pathetic.",
  "%s is mathematically dead and totally desperate.",
  "%s, I will sue him just for fun",
  "%s should be forced to take an IQ test",
  "Little %s, pathetic!",
  "%s only makes bad deals!",
  "%s is unattractive both inside and out. I fully understand why her former husband left her for a man- he made a good decision."
]

post '/insult' do
  if params[:token] != ENV["SLACK_VERIFY_TOKEN"]
    halt 403, "Incorrect slack token"
  end

  HTTParty.post(params[:response_url],
                body: { response_type: "in_channel", text: insults.sample % params[:text] }.to_json,
                headers: { "Content-Type" => "application/json" })
  status 200
end
