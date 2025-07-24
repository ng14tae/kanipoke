class ChangeColumnToUser < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :encrypted_password, :crypted_password
  end
end
