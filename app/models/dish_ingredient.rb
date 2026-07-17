class DishIngredient < ApplicationRecord
  belongs_to :dish
  belongs_to :ingredient

  validates :suggested_quantity, presence: true
  validates :ingredient_id, uniqueness: { scope: :dish_id }
end
