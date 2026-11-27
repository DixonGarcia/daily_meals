# API controller to expose and import weekly meal plans programmatically.
# Enriches each day with nested dish details, ingredients, and overnight defrost items
# so a single HTTP call can power daily Telegram/WhatsApp household notifications.
class Api::V1::MealPlansController < Api::V1::BaseController
  # GET /api/v1/meal_plans
  # Returns active weekly meal plans including nested lunch/dinner dishes, ingredients, and defrost items.
  #
  # @return [void]
  def index
    plans = MealPlan.includes(
      lunch_dish: { dish_ingredients: :ingredient },
      dinner_dish: { dish_ingredients: :ingredient }
    ).all

    payload = plans.map do |plan|
      {
        id: plan.id,
        day_of_week: plan.day_of_week,
        lunch_dish_id: plan.lunch_dish_id,
        dinner_dish_id: plan.dinner_dish_id,
        lunch_dish: serialize_dish(plan.lunch_dish),
        dinner_dish: serialize_dish(plan.dinner_dish),
        defrost_items: plan.defrost_ingredient_names
      }
    end

    render json: payload
  end

  # POST /api/v1/meal_plans/import
  # Imports the weekly meal plan suggestions atomically inside a transaction.
  #
  # @return [void]
  def import
    meal_plan_payload = params.expect(:meal_plan)

    success = true
    ActiveRecord::Base.transaction do
      meal_plan_payload.each do |item|
        day = item[:day]
        lunch_id = item[:lunch_dish_id]
        dinner_id = item[:dinner_dish_id]

        plan = MealPlan.find_or_initialize_by(day_of_week: day)
        plan.lunch_dish_id = lunch_id
        plan.dinner_dish_id = dinner_id

        unless plan.save
          success = false
          raise ActiveRecord::Rollback
        end
      end
    end

    if success
      render json: { status: "success" }, status: :ok
    else
      render json: { error: "Failed to import meal plan" }, status: :unprocessable_entity
    end
  end

  private

  # Serializes a Dish with its ingredients and supermarket sections for API consumers.
  #
  # @param dish [Dish, nil]
  # @return [Hash, nil]
  def serialize_dish(dish)
    return nil unless dish

    {
      id: dish.id,
      name: dish.name,
      ingredients: dish.dish_ingredients.map do |di|
        {
          name: di.ingredient.name,
          quantity: di.suggested_quantity,
          supermarket_section: di.ingredient.supermarket_section
        }
      end
    }
  end
end
