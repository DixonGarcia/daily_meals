# Represents a food dish in the catalog.
# A dish belongs to a category (e.g., Breakfast, Lunch, Dinner) and has multiple ingredients through DishIngredient.
#
# @attr [String] name Name of the dish (must be unique).
# @attr [String] category Category of the meal (Breakfast, Lunch, Dinner, Snack, Other).
class Dish < ApplicationRecord
  # Allowed meal categories for a dish.
  CATEGORIES = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other'].freeze

  has_many :dish_ingredients, dependent: :destroy
  has_many :ingredients, through: :dish_ingredients

  accepts_nested_attributes_for :dish_ingredients, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
end
