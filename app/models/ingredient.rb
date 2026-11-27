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

  # Normalizes a raw section label case-insensitively to one of Ingredient::SECTIONS.
  #
  # @param raw_section [String, nil] Raw section name.
  # @return [String] Matching canonical section or "Otros".
  def self.normalize_section(raw_section)
    cleaned = raw_section.to_s.strip
    SECTIONS.find { |section| section.casecmp?(cleaned) } || "Otros"
  end

  # Finds an existing ingredient case-insensitively by name, or creates it with a normalized section.
  #
  # @param name [String] Ingredient name.
  # @param supermarket_section [String, nil] Optional section name to normalize when creating.
  # @return [Ingredient]
  # @raise [ActiveRecord::RecordInvalid] if creation fails validation.
  def self.find_or_create_normalized!(name:, supermarket_section: nil)
    cleaned_name = name.to_s.strip
    where("LOWER(name) = ?", cleaned_name.downcase).first ||
      create!(name: cleaned_name, supermarket_section: normalize_section(supermarket_section))
  end
end
