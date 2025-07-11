class AddActionPortToBots < ActiveRecord::Migration[8.0]
  def change
    add_column :bots, :action_port, :integer
  end
end
