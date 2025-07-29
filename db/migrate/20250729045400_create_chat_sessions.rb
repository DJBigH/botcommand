class CreateChatSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_sessions do |t|
      t.references :bot, null: false, foreign_key: true
      t.string :name
      t.string :phone
      t.boolean :active
      t.boolean :admin_joined

      t.timestamps
    end
  end
end
