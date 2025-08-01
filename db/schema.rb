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

ActiveRecord::Schema[7.2].define(version: 2025_07_25_020647) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "battles", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "opponent_id"
    t.integer "user_card"
    t.integer "opponent_card"
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.integer "loser_id"
    t.integer "status", default: 0
    t.index ["opponent_id"], name: "index_battles_on_opponent_id"
    t.index ["user_id"], name: "index_battles_on_user_id"
  end

  create_table "characters", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "personality", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "crypted_password", default: "", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "salt"
  end

  add_foreign_key "battles", "users"
  add_foreign_key "battles", "users", column: "opponent_id"
end
