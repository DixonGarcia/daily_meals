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

  scope :with_dishes_and_ingredients, lambda {
    includes(
      lunch_dish: { dish_ingredients: :ingredient },
      dinner_dish: { dish_ingredients: :ingredient }
    )
  }

  validates :day_of_week, presence: true, uniqueness: true, inclusion: { in: DAYS_OF_WEEK }

  # Returns the cyclic next weekday for a given weekday name (wrapping Sunday to Monday).
  #
  # @param day_name [String] Canonical English weekday name from DAYS_OF_WEEK.
  # @return [String] Next weekday name.
  def self.next_day_for(day_name)
    idx = DAYS_OF_WEEK.index(day_name.to_s) || 0
    DAYS_OF_WEEK[(idx + 1) % DAYS_OF_WEEK.length]
  end

  # Atomically imports an array of weekday schedule hashes inside a transaction.
  # Rolls back and returns false if any entry fails validation.
  #
  # @param entries [Array<Hash, ActionController::Parameters>] Entries with :day, :lunch_dish_id, :dinner_dish_id.
  # @return [Boolean] true if all entries saved successfully, false otherwise.
  def self.import_schedule!(entries)
    return false unless entries.is_a?(Array)

    success = true
    ActiveRecord::Base.transaction do
      entries.each do |item|
        plan = find_or_initialize_by(day_of_week: item[:day] || item["day"])
        plan.lunch_dish_id = item[:lunch_dish_id] || item["lunch_dish_id"]
        plan.dinner_dish_id = item[:dinner_dish_id] || item["dinner_dish_id"]

        unless plan.save
          success = false
          raise ActiveRecord::Rollback
        end
      end
    end
    success
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
