class CreateIntegrations < ActiveRecord::Migration[5.0]
  def change
    create_table :integrations do |t|
      t.string :user_id
      t.string :team_id
      t.string :user_token
      t.string :bot_token
      t.string :scope
    end
  end
end
