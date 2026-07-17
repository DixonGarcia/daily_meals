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

ActiveRecord::Schema[7.2].define(version: 2026_07_17_163805) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.index ["name"], name: "index_dishes_on_name", unique: true
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name", null: false
    t.string "supermarket_section", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ingredients_on_name", unique: true
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

  add_foreign_key "dish_ingredients", "dishes"
  add_foreign_key "dish_ingredients", "ingredients"
  add_foreign_key "meal_plans", "dishes", column: "dinner_dish_id"
  add_foreign_key "meal_plans", "dishes", column: "lunch_dish_id"
end
