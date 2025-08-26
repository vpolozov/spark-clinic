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

ActiveRecord::Schema[8.0].define(version: 2025_08_26_131713) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.jsonb "settings", default: {}
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["settings"], name: "index_accounts_on_settings", using: :gin
    t.index ["slug"], name: "index_accounts_on_slug", unique: true, where: "(slug IS NOT NULL)"
  end

  create_table "observations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "patient_id", null: false
    t.string "type", null: false
    t.string "status", default: "final"
    t.string "category"
    t.string "code"
    t.string "interpretation"
    t.jsonb "reference_range", default: {}
    t.datetime "recorded_at", null: false
    t.jsonb "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_observations_on_account_id"
    t.index ["code"], name: "index_observations_on_code"
    t.index ["data"], name: "index_observations_on_data", using: :gin
    t.index ["patient_id"], name: "index_observations_on_patient_id"
    t.index ["recorded_at"], name: "index_observations_on_recorded_at"
    t.index ["reference_range"], name: "index_observations_on_reference_range", using: :gin
    t.index ["type"], name: "index_observations_on_type"
  end

  create_table "patients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "external_id"
    t.string "name"
    t.date "dob"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_patients_on_account_id"
    t.index ["external_id"], name: "index_patients_on_external_id"
  end

  add_foreign_key "observations", "accounts"
  add_foreign_key "observations", "patients"
  add_foreign_key "patients", "accounts"
end
