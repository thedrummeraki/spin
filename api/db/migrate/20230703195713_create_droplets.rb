class CreateDroplets < ActiveRecord::Migration[7.0]
  def change
    create_table :droplets do |t|
      t.string :digitalocean_id, null: false, unique: true
      t.bigint :project_request_id, null: false

      t.timestamps
    end
  end
end
