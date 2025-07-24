class CreateCharacters < ActiveRecord::Migration[7.2]
  def change
    create_table :characters do |t|
      t.string :first_name,               null: false
      t.string :last_name,                null: false
      t.string :personality,              null: false
      t.string :description,              null: false

      t.timestamps null: false
    end
  end
end
