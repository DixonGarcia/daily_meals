# Join model linking a Dish to its required Ingredients.
# Specifies the suggested quantity of an ingredient for a specific dish.
#
# @attr [String] suggested_quantity Described amount (e.g. "500g", "2 units").
# @attr [Integer] dish_id Associated Dish ID.
# @attr [Integer] ingredient_id Associated Ingredient ID.
class DishIngredient < ApplicationRecord
  belongs_to :dish
  belongs_to :ingredient

  validates :suggested_quantity, presence: true
  validates :ingredient_id, uniqueness: { scope: :dish_id }
end
