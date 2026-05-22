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

ActiveRecord::Schema[8.0].define(version: 2026_05_23_000400) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "bill_clients", force: :cascade do |t|
    t.bigint "bill_id", null: false
    t.bigint "client_id", null: false
    t.bigint "shared_by_id"
    t.datetime "shared_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id", "client_id"], name: "index_bill_clients_on_bill_id_and_client_id", unique: true
    t.index ["client_id"], name: "index_bill_clients_on_client_id"
  end

  create_table "bill_issues", force: :cascade do |t|
    t.bigint "bill_id", null: false
    t.bigint "issue_id", null: false
    t.bigint "added_by_id"
    t.datetime "added_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id", "issue_id"], name: "index_bill_issues_on_bill_id_and_issue_id", unique: true
    t.index ["issue_id"], name: "index_bill_issues_on_issue_id"
  end

  create_table "bill_people", force: :cascade do |t|
    t.bigint "bill_id", null: false
    t.bigint "person_id", null: false
    t.bigint "added_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id", "person_id"], name: "index_bill_people_on_bill_id_and_person_id", unique: true
    t.index ["person_id"], name: "index_bill_people_on_person_id"
  end

  create_table "bills", force: :cascade do |t|
    t.string "bill_number"
    t.integer "chamber"
    t.integer "session_year"
    t.string "title", null: false
    t.text "description"
    t.text "notes"
    t.string "tags", default: [], array: true
    t.integer "status", default: 0, null: false
    t.bigint "companion_bill_id"
    t.string "external_id"
    t.string "source_url"
    t.datetime "last_synced_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chamber"], name: "index_bills_on_chamber"
    t.index ["companion_bill_id"], name: "index_bills_on_companion_bill_id"
    t.index ["external_id"], name: "index_bills_on_external_id"
    t.index ["session_year"], name: "index_bills_on_session_year"
    t.index ["status"], name: "index_bills_on_status"
    t.index ["tags"], name: "index_bills_on_tags", using: :gin
  end

  create_table "client_issues", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "issue_id", null: false
    t.bigint "shared_by_id"
    t.datetime "shared_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "issue_id"], name: "index_client_issues_on_client_id_and_issue_id", unique: true
    t.index ["client_id"], name: "index_client_issues_on_client_id"
    t.index ["issue_id"], name: "index_client_issues_on_issue_id"
  end

  create_table "client_staff", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "user_id"], name: "index_client_staff_on_client_id_and_user_id", unique: true
    t.index ["client_id"], name: "index_client_staff_on_client_id"
    t.index ["user_id"], name: "index_client_staff_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "legal_name", null: false
    t.string "display_name", null: false
    t.datetime "discarded_at"
    t.datetime "deactivated_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deactivated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((legal_name)::text)", name: "index_clients_on_lower_legal_name", unique: true
    t.index ["discarded_at", "updated_at"], name: "index_clients_on_discarded_at_and_updated_at"
    t.index ["discarded_at"], name: "index_clients_on_discarded_at"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "created_by_id"
    t.string "token_digest", null: false
    t.string "email_snapshot", null: false
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invite_as"
    t.index ["created_by_id"], name: "index_invitations_on_created_by_id"
    t.index ["person_id"], name: "index_invitations_on_person_id"
    t.index ["token_digest"], name: "index_invitations_on_token_digest", unique: true
  end

  create_table "issue_people", force: :cascade do |t|
    t.bigint "issue_id", null: false
    t.bigint "person_id", null: false
    t.bigint "added_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id", "person_id"], name: "index_issue_people_on_issue_id_and_person_id", unique: true
    t.index ["issue_id"], name: "index_issue_people_on_issue_id"
    t.index ["person_id"], name: "index_issue_people_on_person_id"
  end

  create_table "issues", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.text "notes"
    t.string "tags", default: [], array: true
    t.integer "status", default: 0, null: false
    t.datetime "closed_at"
    t.bigint "closed_by_id"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_issues_on_status"
    t.index ["tags"], name: "index_issues_on_tags", using: :gin
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "role", default: "user", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "people", force: :cascade do |t|
    t.bigint "user_id"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "display_name", null: false
    t.string "email"
    t.string "phone"
    t.string "title"
    t.string "organization_name"
    t.text "notes"
    t.datetime "discarded_at"
    t.datetime "deactivated_at"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.bigint "deactivated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.index "lower((display_name)::text)", name: "index_people_on_lower_display_name"
    t.index "lower((email)::text)", name: "index_people_on_lower_email", where: "(email IS NOT NULL)"
    t.index ["client_id"], name: "index_people_on_client_id"
    t.index ["created_by_id"], name: "index_people_on_created_by_id"
    t.index ["deactivated_by_id"], name: "index_people_on_deactivated_by_id"
    t.index ["discarded_at"], name: "index_people_on_discarded_at"
    t.index ["updated_by_id"], name: "index_people_on_updated_by_id"
    t.index ["user_id"], name: "index_people_on_user_id"
    t.index ["user_id"], name: "index_people_on_user_id_unique_when_present", unique: true, where: "(user_id IS NOT NULL)"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.string "revocation_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "discarded_at"
    t.boolean "system_user", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["system_user"], name: "index_users_on_system_user"
  end

  add_foreign_key "bill_clients", "bills"
  add_foreign_key "bill_clients", "clients"
  add_foreign_key "bill_clients", "users", column: "shared_by_id"
  add_foreign_key "bill_issues", "bills"
  add_foreign_key "bill_issues", "issues"
  add_foreign_key "bill_issues", "users", column: "added_by_id"
  add_foreign_key "bill_people", "bills"
  add_foreign_key "bill_people", "people"
  add_foreign_key "bill_people", "users", column: "added_by_id"
  add_foreign_key "bills", "bills", column: "companion_bill_id"
  add_foreign_key "bills", "users", column: "created_by_id"
  add_foreign_key "bills", "users", column: "updated_by_id"
  add_foreign_key "client_issues", "clients"
  add_foreign_key "client_issues", "issues"
  add_foreign_key "client_issues", "users", column: "shared_by_id"
  add_foreign_key "client_staff", "clients"
  add_foreign_key "client_staff", "users"
  add_foreign_key "clients", "users", column: "created_by_id"
  add_foreign_key "clients", "users", column: "deactivated_by_id"
  add_foreign_key "clients", "users", column: "updated_by_id"
  add_foreign_key "conversations", "users"
  add_foreign_key "invitations", "people"
  add_foreign_key "invitations", "users", column: "created_by_id"
  add_foreign_key "issue_people", "issues"
  add_foreign_key "issue_people", "people"
  add_foreign_key "issue_people", "users", column: "added_by_id"
  add_foreign_key "issues", "users", column: "closed_by_id"
  add_foreign_key "issues", "users", column: "created_by_id"
  add_foreign_key "issues", "users", column: "updated_by_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "people", "clients"
  add_foreign_key "people", "users"
  add_foreign_key "people", "users", column: "created_by_id"
  add_foreign_key "people", "users", column: "deactivated_by_id"
  add_foreign_key "people", "users", column: "updated_by_id"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
