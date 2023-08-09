# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_07_08_042404) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clusters", force: :cascade do |t|
    t.string "digitalocean_uuid", null: false
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "domains", force: :cascade do |t|
    t.string "name", null: false
    t.string "digitalocean_id"
    t.bigint "project_request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_request_id"], name: "index_domains_on_project_request_id"
  end

  create_table "droplets", force: :cascade do |t|
    t.string "digitalocean_id", null: false
    t.bigint "project_request_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "app_url"
    t.string "status", default: "pending", null: false
  end

  create_table "project_requests", force: :cascade do |t|
    t.string "email", null: false
    t.string "project_slug", null: false
    t.string "code"
    t.datetime "keep_until", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ssh_keys", force: :cascade do |t|
    t.string "public_key"
    t.string "digitalocean_id"
    t.bigint "droplet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["droplet_id"], name: "index_ssh_keys_on_droplet_id"
  end

  add_foreign_key "domains", "project_requests"
  add_foreign_key "ssh_keys", "droplets"
end
