class MealPlan < ApplicationRecord
  DAYS_OF_WEEK = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].freeze

  belongs_to :lunch_dish, class_name: 'Dish', optional: true
  belongs_to :dinner_dish, class_name: 'Dish', optional: true

  validates :day_of_week, presence: true, uniqueness: true, inclusion: { in: DAYS_OF_WEEK }
end
