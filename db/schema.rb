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

ActiveRecord::Schema[8.0].define(version: 2025_07_09_020410) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "endpoints", force: :cascade do |t|
    t.string "name"
    t.integer "endpoint_type"
    t.string "url"
    t.string "ip"
    t.integer "port"
    t.integer "status"
    t.boolean "enabled"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_checked_at"
    t.integer "check_interval_seconds"
    t.integer "check_offset_seconds"
    t.integer "check_offset_bucket"
    t.string "smtp_host"
    t.integer "smtp_port"
    t.boolean "smtp_use_tls"
    t.string "dns_hostname"
    t.index ["enabled", "last_checked_at"], name: "index_endpoints_on_enabled_and_last_checked_at"
    t.index ["user_id"], name: "index_endpoints_on_user_id"
  end

  create_table "status_changes", force: :cascade do |t|
    t.bigint "endpoint_id", null: false
    t.integer "status"
    t.decimal "response_time_ms", precision: 10, scale: 3
    t.datetime "checked_at"
    t.string "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checked_at"], name: "index_status_changes_on_checked_at"
    t.index ["endpoint_id", "checked_at"], name: "index_status_changes_on_endpoint_id_and_checked_at"
    t.index ["endpoint_id"], name: "index_status_changes_on_endpoint_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "endpoints", "users"
  add_foreign_key "status_changes", "endpoints"
end
