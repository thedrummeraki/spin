class CreateProjectRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :project_requests do |t|
      t.string :email, null: false
      t.string :project_slug, null: false
      t.string :code

      t.datetime :keep_until, null: false

      t.timestamps
    end
  end
end
