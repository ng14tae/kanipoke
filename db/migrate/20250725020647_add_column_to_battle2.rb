class AddColumnToBattle2 < ActiveRecord::Migration[7.2]
  def change
    add_column :battles, :status, :integer, default: 0
  end
end