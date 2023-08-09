class AddStatusToDroplets < ActiveRecord::Migration[7.0]
  def change
    add_column :droplets, :status, :string, null: false, default: 'pending'
  end
end
