class CreateHouseholdSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :household_settings do |t|
      t.integer :servings_multiplier, default: 2, null: false
      t.text :diet_guidelines, default: "", null: false

      t.timestamps
    end
  end
end
