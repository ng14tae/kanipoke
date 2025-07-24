class DeviseCreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :encrypted_password, null: false, default: ""
      t.string :first_name,               null: false
      t.string :last_name,               null: false
      t.integer :role,              null: false, default: 0  # 0: user, 1: admin

      t.timestamps null: false
    end
  end
end
