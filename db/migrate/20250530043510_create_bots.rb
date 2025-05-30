class CreateBots < ActiveRecord::Migration[7.0]
  def change
    create_table :bots do |t|
      t.string :name
      t.string :path # folder của bot trên server
      t.timestamps
    end
  end
end