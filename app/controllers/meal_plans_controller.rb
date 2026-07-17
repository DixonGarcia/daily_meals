# Handles dashboard and calendar actions for MealPlan planning.
class MealPlansController < ApplicationController
  # GET /
  # GET /meal_plans
  # Renders the dashboard featuring the weekly calendar, shopping list, and AI copilot forms.
  # @return [void]
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

  # PATCH /meal_plans/update_day
  # Updates the lunch and dinner dish choices for a given day.
  # @return [void]
  def update_day
    day = params.expect(:day_of_week)
    lunch_id = params[:lunch_dish_id].presence
    dinner_id = params[:dinner_dish_id].presence

    plan = MealPlan.find_or_initialize_by(day_of_week: day)
    plan.lunch_dish_id = lunch_id
    plan.dinner_dish_id = dinner_id

    day_translated = t("days_of_week.#{day.downcase}", default: day)

    if plan.save
      redirect_to root_path, notice: t('meal_plans.controller.updated', day: day_translated)
    else
      redirect_to root_path, alert: t('meal_plans.controller.error_update', day: day_translated, errors: plan.errors.full_messages.join(', '))
    end
  end
end
