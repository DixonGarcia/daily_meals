class AiCopilotService
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
