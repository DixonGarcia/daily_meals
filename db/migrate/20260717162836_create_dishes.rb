class CreateDishes < ActiveRecord::Migration[7.2]
  def change
    create_table :dishes do |t|
      t.string :name, null: false
      t.string :category, null: false

      t.timestamps
    end
    add_index :dishes, :name, unique: true
  end
end
