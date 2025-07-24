class AddSorceryToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :salt, :string
  end
end
