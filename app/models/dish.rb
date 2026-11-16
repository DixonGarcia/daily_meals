# Represents a food dish in the catalog.
# A dish belongs to one or more categories (e.g., Lunch, Dinner) and has multiple ingredients through DishIngredient.
#
# @attr [String] name Name of the dish (must be unique).
# @attr [String] category Primary meal category kept in sync with categories.first for backward compatibility.
# @attr [Array<String>] categories Multi-select meal categories from Dish::CATEGORIES.
class Dish < ApplicationRecord
  # Allowed meal categories for a dish.
  CATEGORIES = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other'].freeze

  has_many :dish_ingredients, dependent: :destroy
  has_many :ingredients, through: :dish_ingredients

  accepts_nested_attributes_for :dish_ingredients, allow_destroy: true, reject_if: :all_blank

  scope :for_category, ->(cat) { where("categories @> ?", [cat].to_json) }

  before_validation :sync_categories_and_primary_category

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validate :validate_categories_inclusion

  # Assigns the categories array, stripping blank values while preserving order and uniqueness.
  #
  # @param values [Array<String>, String, nil]
  # @return [Array<String>]
  def categories=(values)
    cleaned = Array(values).map { |v| v.to_s.strip }.reject(&:blank?).uniq
    super(cleaned)
    self[:category] = cleaned.first if cleaned.any?
  end

  # Returns the effective list of categories for this dish.
  #
  # @return [Array<String>]
  def effective_categories
    list = Array(categories).reject(&:blank?)
    return list if list.any?

    category.present? ? [category] : []
  end

  private

  # Synchronizes `categories` and `category` so both single-category and multi-category callers stay consistent.
  #
  # @return [void]
  def sync_categories_and_primary_category
    cleaned = Array(categories).map { |v| v.to_s.strip }.reject(&:blank?).uniq

    if cleaned.empty? && category.present? && !@categories_explicitly_set_empty
      cleaned = [category.to_s.strip]
    end

    if attributes_changed_only_category? && category.present?
      cleaned = [category.to_s.strip]
    end

    self[:categories] = cleaned
    self[:category] = cleaned.first
  end

  # Checks whether category= was modified without modifying categories=.
  #
  # @return [Boolean]
  def attributes_changed_only_category?
    will_save_change_to_category? && !will_save_change_to_categories?
  end

  # Validates that categories is non-empty and all entries are included in Dish::CATEGORIES.
  #
  # @return [void]
  def validate_categories_inclusion
    list = Array(categories)
    if list.empty?
      errors.add(:categories, :blank)
      return
    end

    invalid = list - CATEGORIES
    if invalid.any?
      errors.add(:categories, :inclusion)
    end
  end
end
