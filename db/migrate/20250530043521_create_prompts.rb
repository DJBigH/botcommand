class CreatePrompts < ActiveRecord::Migration[7.0]
  def change
    create_table :prompts do |t|
      t.references :bot, foreign_key: true
      t.text :question
      t.text :answer
      t.timestamps
    end
  end
end