class AddCategoryToPrompts < ActiveRecord::Migration[8.0]
  def change
    add_column :prompts, :category, :string
  end
end
