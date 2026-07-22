# API controller to expose and import weekly meal plan programmatically.
class Api::V1::MealPlansController < Api::V1::BaseController
  # GET /api/v1/meal_plans
  # Returns the active weekly meal plans.
  # @return [void]
  def index
    plans = MealPlan.includes(:lunch_dish, :dinner_dish).all
    render json: plans.as_json(only: [:id, :day_of_week, :lunch_dish_id, :dinner_dish_id])
  end

  # POST /api/v1/meal_plans/import
  # Imports the weekly meal plan suggestions atomically inside a transaction.
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
      render json: { status: 'success' }, status: :ok
    else
      render json: { error: 'Failed to import meal plan' }, status: :unprocessable_entity
    end
  end
end
