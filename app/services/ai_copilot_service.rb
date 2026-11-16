# Service to handle conversational AI Copilot planning with Gemini as well as JSON import/export.
class AiCopilotService
  # Initializes the service with an optional GeminiClient dependency.
  #
  # @param gemini_client [GeminiClient, nil]
  def initialize(gemini_client: nil)
    @gemini_client = gemini_client
  end

  # Exports the catalog of dishes alongside the user's restrictions.
  #
  # @param restrictions [String, nil] The restrictions textual input from the user.
  # @return [Hash] The catalog hash with :dish_catalog and :restrictions.
  def export_catalog(restrictions)
    dishes = Dish.order(:name).map do |dish|
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
  rescue => _e
    false
  end

  # Conducts a conversational turn with Gemini, persisting both the user message and the
  # assistant reply alongside any sanitized weekly menu proposal.
  #
  # @param session [AiChatSession] The active chat session.
  # @param user_message [String] Natural language prompt from the owner.
  # @param parameters [Hash] Planning parameters selected in the UI.
  # @return [AiChatMessage] The persisted assistant message.
  def converse!(session:, user_message:, parameters: {})
    merged_params = session.effective_parameters.merge(parameters.to_h.stringify_keys)
    cleaned_message = user_message.to_s.strip

    history = session.ai_chat_messages.map do |msg|
      { role: msg.role, content: msg.content }
    end
    history << { role: "user", content: cleaned_message }

    response = begin
      client.generate_plan_response(
        system_instruction: build_system_instruction(merged_params),
        messages: history
      )
    rescue GeminiClient::ConfigurationError
      raise unless Rails.env.development?

      build_local_development_response(cleaned_message, merged_params)
    end

    sanitized_plan = sanitize_proposed_plan(response[:meal_plan])

    assistant_message = nil
    ActiveRecord::Base.transaction do
      session.update!(parameters: merged_params)

      session.ai_chat_messages.create!(
        role: "user",
        content: cleaned_message
      )

      assistant_message = session.ai_chat_messages.create!(
        role: "assistant",
        content: response[:reply].presence || "He actualizado la propuesta de menú.",
        proposed_plan: sanitized_plan
      )

      if sanitized_plan.any?
        session.update!(proposed_plan: sanitized_plan, status: "active")
      end
    end

    assistant_message
  end

  # Atomically loads the session's proposed_plan into the weekly MealPlan schedule
  # and marks the session as applied.
  #
  # @param session [AiChatSession]
  # @return [Boolean] true if applied successfully.
  def apply_session_plan!(session)
    return false if session.proposed_plan.blank?

    applied = false
    ActiveRecord::Base.transaction do
      if import_plan({ meal_plan: session.proposed_plan })
        session.update!(status: "applied")
        applied = true
      else
        raise ActiveRecord::Rollback
      end
    end
    applied
  end

  private

  # Lazily instantiates the GeminiClient.
  #
  # @return [GeminiClient]
  def client
    @gemini_client ||= GeminiClient.new
  end

  # Constructs the system prompt with the current Dish catalog, active MealPlan, and user parameters.
  #
  # @param params [Hash]
  # @return [String]
  def build_system_instruction(params)
    catalog = Dish.order(:name).map { |d| { id: d.id, name: d.name, category: d.category } }
    current_schedule = MealPlan.all.map do |mp|
      { day: mp.day_of_week, lunch_dish_id: mp.lunch_dish_id, dinner_dish_id: mp.dinner_dish_id }
    end

    days_rule = params["days_scope"] == "full_week" ? "Monday through Sunday (all 7 days)" : "Monday through Friday (5 weekdays)"
    slots_rule = []
    slots_rule << "Lunch (lunch_dish_id)" if ActiveModel::Type::Boolean.new.cast(params["include_lunch"])
    slots_rule << "Dinner (dinner_dish_id)" if ActiveModel::Type::Boolean.new.cast(params["include_dinner"])
    repetition_rule = ActiveModel::Type::Boolean.new.cast(params["avoid_repetition"]) ? "Avoid repeating the same dish on consecutive days." : "Repetition is allowed."

    <<~PROMPT
      You are the DailyMeals AI Culinary Copilot. Always write your `reply` in friendly, concise Spanish.
      Use ONLY the dish IDs provided in DISH_CATALOG below. Never invent dish IDs.
      Valid day names for `meal_plan` are strictly: #{MealPlan::DAYS_OF_WEEK.join(', ')}.

      ACTIVE PLANNING PARAMETERS:
      - Target days: #{days_rule}
      - Meal slots to fill: #{slots_rule.join(' and ').presence || 'Lunch and Dinner'}
      - Variety rule: #{repetition_rule}

      DISH_CATALOG (JSON):
      #{catalog.to_json}

      CURRENT_WEEKLY_SCHEDULE (JSON):
      #{current_schedule.to_json}
    PROMPT
  end

  # Filters and sanitizes Gemini's meal_plan output against valid days and existing Dish IDs.
  #
  # @param raw_plan [Array<Hash>]
  # @return [Array<Hash>]
  def sanitize_proposed_plan(raw_plan)
    return [] unless raw_plan.is_a?(Array)

    valid_dish_ids = Dish.pluck(:id).to_set
    valid_days = MealPlan::DAYS_OF_WEEK

    raw_plan.filter_map do |entry|
      next unless entry.is_a?(Hash)

      day = (entry["day"] || entry[:day]).to_s
      next unless valid_days.include?(day)

      raw_lunch = entry["lunch_dish_id"] || entry[:lunch_dish_id]
      raw_dinner = entry["dinner_dish_id"] || entry[:dinner_dish_id]

      lunch_id = raw_lunch.present? && valid_dish_ids.include?(raw_lunch.to_i) ? raw_lunch.to_i : nil
      dinner_id = raw_dinner.present? && valid_dish_ids.include?(raw_dinner.to_i) ? raw_dinner.to_i : nil

      {
        "day" => day,
        "lunch_dish_id" => lunch_id,
        "dinner_dish_id" => dinner_id
      }
    end
  end

  # Generates a deterministic, parameter-aware menu proposal from the local Dish catalog
  # when running in local development without GEMINI_API_KEY configured yet.
  #
  # @param user_message [String]
  # @param params [Hash]
  # @return [Hash] Hash with :reply and :meal_plan.
  def build_local_development_response(user_message, params)
    dishes = Dish.order(:id).to_a
    if dishes.empty?
      return {
        reply: "Aún no tienes platos registrados en tu catálogo. Agrega algunos en la sección «🍽️ Platos» para poder armar tu menú semanal.",
        meal_plan: []
      }
    end

    target_days = params["days_scope"] == "full_week" ? MealPlan::DAYS_OF_WEEK : MealPlan::DAYS_OF_WEEK.first(5)
    include_lunch = ActiveModel::Type::Boolean.new.cast(params["include_lunch"])
    include_dinner = ActiveModel::Type::Boolean.new.cast(params["include_dinner"])

    lunch_pool = dishes.select { |d| d.category.to_s.downcase == "lunch" }.presence || dishes
    dinner_pool = dishes.select { |d| d.category.to_s.downcase == "dinner" }.presence || dishes.reverse

    plan = target_days.each_with_index.map do |day, idx|
      lunch_id = include_lunch ? lunch_pool[idx % lunch_pool.size]&.id : nil
      dinner_idx = (lunch_pool == dinner_pool && dishes.size > 1) ? (idx + 1) : idx
      dinner_id = include_dinner ? dinner_pool[dinner_idx % dinner_pool.size]&.id : nil

      {
        "day" => day,
        "lunch_dish_id" => lunch_id,
        "dinner_dish_id" => dinner_id
      }
    end

    scope_label = params["days_scope"] == "full_week" ? "lunes a domingo" : "lunes a viernes"
    {
      reply: "He preparado una propuesta de menú de #{scope_label} basada en tu catálogo actual y tus parámetros («#{user_message.to_s.truncate(50)}»). Revisa la vista previa abajo y toca «Cargar este Menú en el Calendario» cuando estés conforme. (Nota: modo local activo; agrega GEMINI_API_KEY en .env para usar Gemini en la nube).",
      meal_plan: plan
    }
  end
end
