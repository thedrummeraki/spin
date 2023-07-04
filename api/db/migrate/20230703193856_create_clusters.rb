class CreateClusters < ActiveRecord::Migration[7.0]
  def change
    create_table :clusters do |t|
      t.string :digitalocean_uuid, null: false, unique: true
      t.string :url

      t.timestamps
    end
  end
end
