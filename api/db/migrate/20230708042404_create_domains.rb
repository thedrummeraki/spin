class CreateDomains < ActiveRecord::Migration[7.0]
  def change
    create_table :domains do |t|
      t.string :name, null: false
      t.string :digitalocean_id
      t.references :project_request, foreign_key: true

      t.timestamps
    end
  end
end
