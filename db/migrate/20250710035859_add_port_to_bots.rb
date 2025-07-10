class AddPortToBots < ActiveRecord::Migration[8.0]
  def change
    add_column :bots, :port, :integer
  end
end
