class AddCategoriesToDishes < ActiveRecord::Migration[8.0]
  def up
    add_column :dishes, :categories, :jsonb, null: false, default: []
    add_index :dishes, :categories, using: :gin

    execute <<~SQL
      UPDATE dishes
      SET categories = jsonb_build_array(category)
      WHERE category IS NOT NULL AND category <> ''
    SQL
  end

  def down
    remove_index :dishes, :categories
    remove_column :dishes, :categories
  end
end
