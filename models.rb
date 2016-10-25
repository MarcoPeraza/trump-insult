class User < ActiveRecord::Base
  validates_uniqueness_of :user_id
  validates_presence_of :user_id
  validates_presence_of :access_token
end

class Bot < ActiveRecord::Base
  validates_uniqueness_of :user_id
  validates_presence_of :user_id
  validates_presence_of :access_token
end
