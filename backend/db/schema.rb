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

ActiveRecord::Schema[8.0].define(version: 2026_11_03_102412) do
  create_table "audit_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.string "action", limit: 30, null: false
    t.json "audited_changes", null: false
    t.datetime "created_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable"
    t.index ["user_id", "created_at"], name: "index_audit_logs_on_user_and_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "countries", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "iso_code", limit: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["iso_code"], name: "index_countries_on_iso_code", unique: true
  end

  create_table "currencies", primary_key: "code", id: { type: :string, limit: 3 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.integer "decimal_places", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_currencies_on_name", unique: true
    t.check_constraint "`decimal_places` between 0 and 4", name: "check_currencies_decimal_places"
  end

  create_table "departments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "employees", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "employee_number", limit: 20, null: false
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "email", null: false
    t.bigint "country_id", null: false
    t.bigint "department_id", null: false
    t.bigint "job_title_id", null: false
    t.string "employment_status", default: "active", null: false
    t.date "hired_on", null: false
    t.date "terminated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "department_id", "employment_status"], name: "index_employees_on_country_department_status"
    t.index ["country_id"], name: "index_employees_on_country_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_number"], name: "index_employees_on_employee_number", unique: true
    t.index ["employment_status"], name: "index_employees_on_employment_status"
    t.index ["job_title_id"], name: "index_employees_on_job_title_id"
  end

  create_table "job_titles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_job_titles_on_name", unique: true
  end

  create_table "salary_histories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "created_by_id", null: false
    t.decimal "annual_base_salary", precision: 19, scale: 4, null: false
    t.decimal "annual_bonus", precision: 19, scale: 4, default: "0.0", null: false
    t.decimal "annual_allowances", precision: 19, scale: 4, default: "0.0", null: false
    t.string "currency_code", limit: 3, null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.string "change_reason", limit: 500
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.index ["cancelled_by_id"], name: "index_salary_histories_on_cancelled_by_id"
    t.index ["created_by_id"], name: "index_salary_histories_on_created_by_id"
    t.index ["currency_code", "effective_from"], name: "index_salary_histories_on_currency_and_effective_from"
    t.index ["employee_id", "effective_from"], name: "index_salary_histories_on_employee_and_effective_from"
    t.check_constraint "(`annual_base_salary` >= 0) and (`annual_bonus` >= 0) and (`annual_allowances` >= 0)", name: "check_salary_histories_amounts_non_negative"
    t.check_constraint "(`effective_to` is null) or (`effective_to` > `effective_from`)", name: "check_salary_histories_effective_dates"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "role", default: "hr_manager", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "audit_logs", "users"
  add_foreign_key "employees", "countries"
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "job_titles"
  add_foreign_key "salary_histories", "currencies", column: "currency_code", primary_key: "code"
  add_foreign_key "salary_histories", "employees"
  add_foreign_key "salary_histories", "users", column: "cancelled_by_id"
  add_foreign_key "salary_histories", "users", column: "created_by_id"
end
