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

ActiveRecord::Schema[8.0].define(version: 2026_11_27_153000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_chat_messages", force: :cascade do |t|
    t.bigint "ai_chat_session_id", null: false
    t.string "role", null: false
    t.text "content", null: false
    t.jsonb "proposed_plan", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "proposed_dishes", default: [], null: false
    t.index ["ai_chat_session_id"], name: "index_ai_chat_messages_on_ai_chat_session_id"
  end

  create_table "ai_chat_sessions", force: :cascade do |t|
    t.string "title", null: false
    t.jsonb "parameters", default: {}, null: false
    t.jsonb "proposed_plan", default: [], null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "proposed_dishes", default: [], null: false
  end

  create_table "api_keys", force: :cascade do |t|
    t.string "name", null: false
    t.string "token_digest", null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
  end

  create_table "dish_ingredients", force: :cascade do |t|
    t.bigint "dish_id", null: false
    t.bigint "ingredient_id", null: false
    t.string "suggested_quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dish_id", "ingredient_id"], name: "index_dish_ingredients_on_dish_id_and_ingredient_id", unique: true
    t.index ["dish_id"], name: "index_dish_ingredients_on_dish_id"
    t.index ["ingredient_id"], name: "index_dish_ingredients_on_ingredient_id"
  end

  create_table "dishes", force: :cascade do |t|
    t.string "name", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "categories", default: [], null: false
    t.index ["categories"], name: "index_dishes_on_categories", using: :gin
    t.index ["name"], name: "index_dishes_on_name", unique: true
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name", null: false
    t.string "supermarket_section", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pantry_staple", default: false, null: false
    t.index ["name"], name: "index_ingredients_on_name", unique: true
  end

  create_table "meal_plan_histories", force: :cascade do |t|
    t.integer "year", null: false
    t.integer "week_number", null: false
    t.date "week_start_date", null: false
    t.date "week_end_date", null: false
    t.jsonb "plan_snapshot", default: [], null: false
    t.string "source", default: "manual", null: false
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year", "week_number"], name: "index_meal_plan_histories_on_year_and_week_number", unique: true
  end

  create_table "meal_plans", force: :cascade do |t|
    t.string "day_of_week", null: false
    t.bigint "lunch_dish_id"
    t.bigint "dinner_dish_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day_of_week"], name: "index_meal_plans_on_day_of_week", unique: true
    t.index ["dinner_dish_id"], name: "index_meal_plans_on_dinner_dish_id"
    t.index ["lunch_dish_id"], name: "index_meal_plans_on_lunch_dish_id"
  end

  add_foreign_key "ai_chat_messages", "ai_chat_sessions", on_delete: :cascade
  add_foreign_key "dish_ingredients", "dishes"
  add_foreign_key "dish_ingredients", "ingredients"
  add_foreign_key "meal_plans", "dishes", column: "dinner_dish_id"
  add_foreign_key "meal_plans", "dishes", column: "lunch_dish_id"
end
