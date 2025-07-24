class AddColumnToBattle < ActiveRecord::Migration[7.2]
  def change
    add_column :battles, :winner_id, :integer
    add_column :battles, :loser_id, :integer
  end
end
