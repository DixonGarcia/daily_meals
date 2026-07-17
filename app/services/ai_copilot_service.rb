# Service to handle the import and export operations for the AI Copilot features.
# Enables JSON-based sharing of dishes and meal plans.
class AiCopilotService
  # Exports the catalog of dishes alongside the user's restrictions.
  #
  # @param restrictions [String, nil] The restrictions textual input from the user.
  # @return [Hash] The catalog hash with :dish_catalog and :restrictions.
  def export_catalog(restrictions)
    dishes = Dish.all.map do |dish|
      {
        id: dish.id,
        name: dish.name,
        category: dish.category
      }
    end

    {
      dish_catalog: dishes,
      restrictions: restrictions
    }
  end

  # Imports a meal plan from a JSON payload or parsed Hash structure.
  # Operates inside a transaction to guarantee atomicity.
  #
  # @param payload [String, Hash] The JSON payload or hash describing the planned days and dishes.
  # @return [Boolean] true if the entire import was successful, false otherwise.
  def import_plan(payload)
    data = payload.is_a?(String) ? JSON.parse(payload, symbolize_names: true) : payload

    # Ensure it's active-support hash with indifferent access to handle symbol/string keys
    data = data.with_indifferent_access if data.respond_to?(:with_indifferent_access)

    return false unless data[:meal_plan].is_a?(Array)

    success = true
    ActiveRecord::Base.transaction do
      data[:meal_plan].each do |item|
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
    success
  rescue => e
    false
  end
end
