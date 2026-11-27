class AddPantryStapleToIngredients < ActiveRecord::Migration[8.0]
  def change
    add_column :ingredients, :pantry_staple, :boolean, default: false, null: false
  end
end
