class AddBotIdentifierToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :bots, :bot_identifier, :string
  end
end
