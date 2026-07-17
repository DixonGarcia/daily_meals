class CreateMealPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :meal_plans do |t|
      t.string :day_of_week, null: false
      t.references :lunch_dish, foreign_key: { to_table: :dishes }, null: true
      t.references :dinner_dish, foreign_key: { to_table: :dishes }, null: true

      t.timestamps
    end
    add_index :meal_plans, :day_of_week, unique: true
  end
end
