class CreateBattles < ActiveRecord::Migration[7.2]
  def change
    create_table :battles do |t|
    t.references :user, foreign_key: true
    t.references :opponent, foreign_key: { to_table: :users }
    t.integer :user_card
    t.integer :opponent_card
    t.string :result
      t.timestamps
    end
  end
end
