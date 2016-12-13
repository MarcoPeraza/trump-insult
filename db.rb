class Integration < ActiveRecord::Base
  validates_uniqueness_of :user_id
  validates_presence_of :user_id
  validates_presence_of :team_id
  validates_presence_of :user_token
  validates_presence_of :bot_token
end
