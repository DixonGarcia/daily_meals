# Represents the planned meals (lunch and dinner) for a specific day of the week.
#
# @attr [String] day_of_week The weekday name (e.g. "Monday"). Must be unique.
# @attr [Integer, nil] lunch_dish_id The ID of the Dish planned for lunch.
# @attr [Integer, nil] dinner_dish_id The ID of the Dish planned for dinner.
class MealPlan < ApplicationRecord
  # Ordered weekdays for the meal plan calendar.
  DAYS_OF_WEEK = [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" ].freeze
  # Supermarket sections whose ingredients typically need overnight defrosting in the fridge.
  DEFROST_SECTIONS = [ "Carnicería", "Congelados" ].freeze

  belongs_to :lunch_dish, class_name: "Dish", optional: true
  belongs_to :dinner_dish, class_name: "Dish", optional: true

  validates :day_of_week, presence: true, uniqueness: true, inclusion: { in: DAYS_OF_WEEK }

  # Returns the cyclic next weekday for a given weekday name (wrapping Sunday to Monday).
  #
  # @param day_name [String] Canonical English weekday name from DAYS_OF_WEEK.
  # @return [String] Next weekday name.
  def self.next_day_for(day_name)
    idx = DAYS_OF_WEEK.index(day_name.to_s) || 0
    DAYS_OF_WEEK[(idx + 1) % DAYS_OF_WEEK.length]
  end

  # Returns sorted unique ingredient names scheduled for this day that belong to DEFROST_SECTIONS.
  #
  # @return [Array<String>]
  def defrost_ingredient_names
    [ lunch_dish, dinner_dish ].compact.flat_map do |dish|
      dish.dish_ingredients.filter_map do |di|
        ingredient = di.ingredient
        next unless ingredient && DEFROST_SECTIONS.include?(ingredient.supermarket_section)

        ingredient.name
      end
    end.uniq.sort
  end
end
