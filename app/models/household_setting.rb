# Singleton record storing household-wide diet guidelines and default servings count.
# Injected automatically into Gemini AI Copilot prompts and used as the default
# multiplier on the shopping list when no device cookie overrides it.
#
# @attr [Integer] servings_multiplier Default number of household servings (1..10).
# @attr [String] diet_guidelines Free-text Spanish rules describing the household diet,
#   meal-prep preferences, local ingredients, and baby-friendly cooking notes.
class HouseholdSetting < ApplicationRecord
  # Default number of servings for a couple household.
  DEFAULT_SERVINGS = 2
  # Minimum allowed servings multiplier.
  MIN_SERVINGS = 1
  # Maximum allowed servings multiplier.
  MAX_SERVINGS = 10

  validates :servings_multiplier,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MIN_SERVINGS,
              less_than_or_equal_to: MAX_SERVINGS
            }

  # Returns the singleton HouseholdSetting record, creating it with sensible defaults if absent.
  #
  # @return [HouseholdSetting]
  def self.current
    first || create!(servings_multiplier: DEFAULT_SERVINGS, diet_guidelines: "")
  end

  # Returns the persisted HouseholdSetting or an unsaved default instance without writing to the database.
  # Suitable for public read-only guest requests.
  #
  # @return [HouseholdSetting]
  def self.current_or_default
    first || new(servings_multiplier: DEFAULT_SERVINGS, diet_guidelines: "")
  end

  # Returns true when household diet guidelines have been configured.
  #
  # @return [Boolean]
  def guidelines_present?
    diet_guidelines.present?
  end
end
