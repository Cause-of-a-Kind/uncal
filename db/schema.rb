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

ActiveRecord::Schema[8.1].define(version: 2026_02_24_163913) do
  create_table "availability_windows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.time "end_time", null: false
    t.integer "schedule_link_id", null: false
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["schedule_link_id", "user_id", "day_of_week"], name: "idx_availability_windows_link_user_day"
    t.index ["schedule_link_id"], name: "index_availability_windows_on_schedule_link_id"
    t.index ["user_id"], name: "index_availability_windows_on_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.integer "invited_by_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "schedule_link_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "schedule_link_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["schedule_link_id", "user_id"], name: "index_schedule_link_members_on_schedule_link_id_and_user_id", unique: true
    t.index ["schedule_link_id"], name: "index_schedule_link_members_on_schedule_link_id"
    t.index ["user_id"], name: "index_schedule_link_members_on_user_id"
  end

  create_table "schedule_links", force: :cascade do |t|
    t.integer "buffer_minutes", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.integer "max_bookings_per_day"
    t.integer "max_future_days", default: 30, null: false
    t.integer "meeting_duration_minutes", null: false
    t.string "meeting_location_type", null: false
    t.string "meeting_location_value"
    t.string "meeting_name", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.string "timezone", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_schedule_links_on_created_by_id"
    t.index ["slug"], name: "index_schedule_links_on_slug", unique: true
    t.index ["status"], name: "index_schedule_links_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.boolean "google_calendar_connected", default: false, null: false
    t.string "google_calendar_refresh_token"
    t.string "google_calendar_token"
    t.datetime "google_calendar_token_expires_at"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "timezone", default: "Etc/UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "availability_windows", "schedule_links"
  add_foreign_key "availability_windows", "users"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "schedule_link_members", "schedule_links"
  add_foreign_key "schedule_link_members", "users"
  add_foreign_key "schedule_links", "users", column: "created_by_id"
  add_foreign_key "sessions", "users"
end
