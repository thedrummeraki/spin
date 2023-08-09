class CreateSshKeys < ActiveRecord::Migration[7.0]
  def change
    create_table :ssh_keys do |t|
      t.string :public_key
      t.string :digitalocean_id
      t.references :droplet, foreign_key: true

      t.timestamps
    end
  end
end
