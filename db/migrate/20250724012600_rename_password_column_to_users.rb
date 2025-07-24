class RenamePasswordColumnToUsers < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :password, :encrypted_password
  end
end
