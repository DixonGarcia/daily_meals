class MealPlansController < ApplicationController
  def index
    # Load all meal plans in order of the week
    days = MealPlan::DAYS_OF_WEEK
    @meal_plans = days.each_with_object({}) do |day, hash|
      hash[day] = MealPlan.find_by(day_of_week: day) || MealPlan.new(day_of_week: day)
    end

    # Load available dishes for selecting in the form
    @dishes = Dish.all.order(:name)

    # Generate dynamic shopping list
    @shopping_list = ShoppingListGenerator.new.generate
  end

  def update_day
    day = params[:day_of_week]
    lunch_id = params[:lunch_dish_id].presence
    dinner_id = params[:dinner_dish_id].presence

    plan = MealPlan.find_or_initialize_by(day_of_week: day)
    plan.lunch_dish_id = lunch_id
    plan.dinner_dish_id = dinner_id

    if plan.save
      redirect_to root_path, notice: "Meal plan for #{day} updated successfully."
    else
      redirect_to root_path, alert: "Could not update meal plan for #{day}: #{plan.errors.full_messages.join(', ')}"
    end
  end
end
