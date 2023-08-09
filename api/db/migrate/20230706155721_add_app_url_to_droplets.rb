class AddAppUrlToDroplets < ActiveRecord::Migration[7.0]
  def change
    add_column :droplets, :app_url, :string
  end
end
