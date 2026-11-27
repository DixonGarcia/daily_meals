# Represents an ingredient used in dishes.
# Ingredients are categorized by their supermarket section for shopping list consolidation.
#
# @attr [String] name Name of the ingredient (must be unique).
# @attr [String] supermarket_section The supermarket aisle/section where this ingredient is found.
# @attr [Boolean] pantry_staple Whether this ingredient is a dry/long-life pantry staple bought biweekly or monthly.
class Ingredient < ApplicationRecord
  # Allowed supermarket sections ordered by practical Venezuelan market stops.
  SECTIONS = [
    "Verdulería",
    "Carnicería",
    "Charcutería",
    "Lácteos",
    "Panadería",
    "Víveres",
    "Despensa",
    "Congelados",
    "Bebidas",
    "Limpieza",
    "Otros"
  ].freeze

  has_many :dish_ingredients, dependent: :destroy
  has_many :dishes, through: :dish_ingredients

  validates :name, presence: true, uniqueness: true
  validates :supermarket_section, presence: true, inclusion: { in: SECTIONS }
end
