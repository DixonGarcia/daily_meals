# Represents the planned meals (lunch and dinner) for a specific day of the week.
#
# @attr [String] day_of_week The weekday name (e.g. "Monday"). Must be unique.
# @attr [Integer, nil] lunch_dish_id The ID of the Dish planned for lunch.
# @attr [Integer, nil] dinner_dish_id The ID of the Dish planned for dinner.
class MealPlan < ApplicationRecord
  # Ordered weekdays for the meal plan calendar.
  DAYS_OF_WEEK = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].freeze

  belongs_to :lunch_dish, class_name: 'Dish', optional: true
  belongs_to :dinner_dish, class_name: 'Dish', optional: true

  validates :day_of_week, presence: true, uniqueness: true, inclusion: { in: DAYS_OF_WEEK }
end
