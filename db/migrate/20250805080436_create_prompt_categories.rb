class CreatePromptCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_categories do |t|
      t.string :name

      t.timestamps
    end
  end
end
