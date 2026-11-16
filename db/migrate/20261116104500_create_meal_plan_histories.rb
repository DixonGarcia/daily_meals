# Creates the meal_plan_histories table for archiving weekly meal schedules.
class CreateMealPlanHistories < ActiveRecord::Migration[8.0]
  # Creates meal_plan_histories with a unique year + week_number index.
  # @return [void]
  def change
    create_table :meal_plan_histories do |t|
      t.integer :year, null: false
      t.integer :week_number, null: false
      t.date :week_start_date, null: false
      t.date :week_end_date, null: false
      t.jsonb :plan_snapshot, null: false, default: []
      t.string :source, null: false, default: "manual"
      t.string :notes

      t.timestamps
    end

    add_index :meal_plan_histories, %i[year week_number], unique: true
  end
end
