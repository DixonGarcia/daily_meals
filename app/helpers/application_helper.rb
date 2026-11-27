# Global helper methods available across all views in the application.
module ApplicationHelper
  # CSS badge class mapping for Dish::CATEGORIES values.
  DISH_CATEGORY_CLASSES = {
    "Breakfast" => "tag-breakfast",
    "Lunch" => "tag-lunch",
    "Dinner" => "tag-dinner",
    "Snack" => "tag-snack"
  }.freeze

  # Returns the Biteclub CSS badge class for a dish category.
  #
  # @param category [String] Canonical Dish category name.
  # @return [String] CSS modifier class name.
  def dish_category_badge_class(category)
    DISH_CATEGORY_CLASSES.fetch(category.to_s, "tag-other")
  end
end
