class Dish < ApplicationRecord
  CATEGORIES = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other'].freeze

  has_many :dish_ingredients, dependent: :destroy
  has_many :ingredients, through: :dish_ingredients

  accepts_nested_attributes_for :dish_ingredients, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
end
