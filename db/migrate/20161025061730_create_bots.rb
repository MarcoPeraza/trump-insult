class CreateBots < ActiveRecord::Migration[5.0]
  def change
    create_table :bots do |t|
      t.string :user_id
      t.string :access_token
      t.string :scope
      t.string :team_id
    end
  end
end
