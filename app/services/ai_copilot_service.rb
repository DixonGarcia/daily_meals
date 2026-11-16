# Service to handle conversational AI Copilot planning with Gemini, on-the-fly dish and ingredient creation,
# dish ingredient autocomplete, and JSON import/export.
class AiCopilotService
  CATEGORY_MAP = {
    "breakfast" => "Breakfast",
    "desayuno" => "Breakfast",
    "lunch" => "Lunch",
    "almuerzo" => "Lunch",
    "dinner" => "Dinner",
    "cena" => "Dinner",
    "snack" => "Snack",
    "merienda" => "Snack",
    "other" => "Other",
    "otro" => "Other"
  }.freeze

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
  # assistant reply alongside any sanitized weekly menu proposal and proposed new dishes.
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

    response = client.generate_plan_response(
      system_instruction: build_system_instruction(merged_params),
      messages: history
    )

    sanitized_dishes = sanitize_proposed_dishes(response[:new_dishes])
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
        proposed_plan: sanitized_plan,
        proposed_dishes: sanitized_dishes
      )

      updates = { status: "active" }
      updates[:proposed_plan] = sanitized_plan if sanitized_plan.any?
      updates[:proposed_dishes] = sanitized_dishes if sanitized_dishes.any? || sanitized_plan.any?
      session.update!(updates)
    end

    assistant_message
  end

  # Atomically creates any included proposed_dishes (and their checked ingredients with overridden quantities),
  # resolves new dish names in proposed_plan to their newly created IDs, and loads the schedule into MealPlan.
  #
  # @param session [AiChatSession]
  # @param dish_overrides [Hash, ActionController::Parameters, nil] Optional user overrides for checkboxes and quantities.
  # @return [Boolean] true if applied successfully.
  def apply_session_plan!(session, dish_overrides: nil)
    return false if session.proposed_plan.blank? && session.proposed_dishes.blank?

    applied = false
    ActiveRecord::Base.transaction do
      created_dishes_by_name = persist_proposed_dishes!(session.proposed_dishes, dish_overrides)

      if session.proposed_plan.present?
        resolved_plan = resolve_plan_dish_ids(session.proposed_plan, created_dishes_by_name)
        unless import_plan({ meal_plan: resolved_plan })
          raise ActiveRecord::Rollback
        end
      end

      session.update!(status: "applied")
      applied = true
    end
    applied
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Suggests a normalized dish category and ingredient list for a dish name using Gemini,
  # matching existing ingredients case-insensitively.
  #
  # @param dish_name [String]
  # @return [Hash] Hash with :category and :ingredients.
  def suggest_ingredients_for_dish(dish_name)
    existing_ingredients = Ingredient.order(:name).to_a
    existing_by_downcase = existing_ingredients.index_by { |i| i.name.downcase.strip }

    raw = client.suggest_dish_ingredients(
      dish_name: dish_name.to_s.strip,
      existing_ingredients: existing_ingredients.map { |i| { name: i.name, supermarket_section: i.supermarket_section } }
    )

    normalized_category = normalize_category(raw[:category])
    ingredients = Array(raw[:ingredients]).filter_map do |item|
      next unless item.is_a?(Hash)

      raw_name = (item["name"] || item[:name]).to_s.strip
      next if raw_name.blank?

      matched = existing_by_downcase[raw_name.downcase]
      section = matched ? matched.supermarket_section : normalize_section(item["supermarket_section"] || item[:supermarket_section])
      qty = (item["suggested_quantity"] || item[:suggested_quantity]).to_s.strip.presence || "1 unidad"

      {
        ingredient_id: matched&.id,
        name: matched ? matched.name : raw_name,
        supermarket_section: section,
        suggested_quantity: qty,
        is_new: matched.nil?
      }
    end

    {
      category: normalized_category,
      ingredients: ingredients
    }
  end

  private

  # Lazily instantiates the GeminiClient.
  #
  # @return [GeminiClient]
  def client
    @gemini_client ||= GeminiClient.new
  end

  # Constructs the system prompt with the current Dish catalog, Ingredient catalog, active MealPlan, and parameters.
  #
  # @param params [Hash]
  # @return [String]
  def build_system_instruction(params)
    catalog = Dish.order(:name).map { |d| { id: d.id, name: d.name, category: d.category } }
    ingredients = Ingredient.order(:name).map { |i| { name: i.name, supermarket_section: i.supermarket_section } }
    current_schedule = MealPlan.all.map do |mp|
      { day: mp.day_of_week, lunch_dish_id: mp.lunch_dish_id, dinner_dish_id: mp.dinner_dish_id }
    end

    days_rule = params["days_scope"] == "full_week" ? "Monday through Sunday (all 7 days)" : "Monday through Friday (5 weekdays)"
    slots_rule = []
    slots_rule << "Lunch (lunch_dish_id / lunch_new_dish_name)" if ActiveModel::Type::Boolean.new.cast(params["include_lunch"])
    slots_rule << "Dinner (dinner_dish_id / dinner_new_dish_name)" if ActiveModel::Type::Boolean.new.cast(params["include_dinner"])
    repetition_rule = ActiveModel::Type::Boolean.new.cast(params["avoid_repetition"]) ? "Avoid repeating the same dish on consecutive days." : "Repetition is allowed."

    <<~PROMPT
      You are the DailyMeals AI Culinary Copilot. Always write your `reply` in friendly, concise Spanish.
      Valid day names for `meal_plan` are strictly: #{MealPlan::DAYS_OF_WEEK.join(', ')}.
      Allowed dish `category` values: #{Dish::CATEGORIES.join(', ')}.
      Allowed ingredient `supermarket_section` values: #{Ingredient::SECTIONS.join(', ')}.

      HOW TO HANDLE EXISTING VS. NEW DISHES:
      1. If a dish already exists in DISH_CATALOG, set `lunch_dish_id` or `dinner_dish_id` to its integer `id` and leave `lunch_new_dish_name` / `dinner_new_dish_name` null.
      2. If the user asks for a dish NOT in DISH_CATALOG, or asks you to invent/suggest new dishes, add each new dish to `new_dishes` with its `name` (in Spanish), `category`, and `ingredients` (reusing exact names from EXISTING_INGREDIENTS whenever applicable, with realistic quantities in Spanish like "500g", "1 lata", "2 unidades"). Then reference that exact dish `name` in `lunch_new_dish_name` or `dinner_new_dish_name` on the scheduled day!

      ACTIVE PLANNING PARAMETERS:
      - Target days: #{days_rule}
      - Meal slots to fill: #{slots_rule.join(' and ').presence || 'Lunch and Dinner'}
      - Variety rule: #{repetition_rule}

      DISH_CATALOG (JSON):
      #{catalog.to_json}

      EXISTING_INGREDIENTS (JSON):
      #{ingredients.to_json}

      CURRENT_WEEKLY_SCHEDULE (JSON):
      #{current_schedule.to_json}
    PROMPT
  end

  # Sanitizes proposed new dishes and their ingredients.
  #
  # @param raw_dishes [Array<Hash>]
  # @return [Array<Hash>]
  def sanitize_proposed_dishes(raw_dishes)
    return [] unless raw_dishes.is_a?(Array)

    raw_dishes.filter_map do |dish|
      next unless dish.is_a?(Hash)

      name = (dish["name"] || dish[:name]).to_s.strip
      next if name.blank?

      category = normalize_category(dish["category"] || dish[:category])
      raw_ings = dish["ingredients"] || dish[:ingredients]
      ingredients = Array(raw_ings).filter_map do |ing|
        next unless ing.is_a?(Hash)

        ing_name = (ing["name"] || ing[:name]).to_s.strip
        next if ing_name.blank?

        {
          "name" => ing_name,
          "supermarket_section" => normalize_section(ing["supermarket_section"] || ing[:supermarket_section]),
          "suggested_quantity" => (ing["suggested_quantity"] || ing[:suggested_quantity]).to_s.strip.presence || "1 unidad"
        }
      end

      {
        "name" => name,
        "category" => category,
        "ingredients" => ingredients
      }
    end
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

      lunch_new_name = (entry["lunch_new_dish_name"] || entry[:lunch_new_dish_name]).to_s.strip.presence
      dinner_new_name = (entry["dinner_new_dish_name"] || entry[:dinner_new_dish_name]).to_s.strip.presence

      row = {
        "day" => day,
        "lunch_dish_id" => lunch_id,
        "dinner_dish_id" => dinner_id
      }
      row["lunch_new_dish_name"] = lunch_new_name if lunch_new_name.present?
      row["dinner_new_dish_name"] = dinner_new_name if dinner_new_name.present?
      row
    end
  end

  # Persists included proposed dishes and their checked ingredients, returning a map of downcased dish name => dish.id.
  #
  # @param proposed_dishes [Array<Hash>]
  # @param dish_overrides [Hash, ActionController::Parameters, nil]
  # @return [Hash<String, Integer>]
  def persist_proposed_dishes!(proposed_dishes, dish_overrides)
    created_map = {}
    dishes_source = extract_dishes_to_persist(proposed_dishes, dish_overrides)

    dishes_source.each do |dish_data|
      next unless dish_data[:included]

      dish_name = dish_data[:name].to_s.strip
      next if dish_name.blank?

      dish = Dish.where("LOWER(name) = ?", dish_name.downcase).first || Dish.new(name: dish_name)
      dish.category = normalize_category(dish_data[:category])
      dish.save!

      dish_data[:ingredients].each do |ing_data|
        next unless ing_data[:included]

        ing_name = ing_data[:name].to_s.strip
        next if ing_name.blank?

        ingredient = Ingredient.where("LOWER(name) = ?", ing_name.downcase).first
        unless ingredient
          ingredient = Ingredient.create!(
            name: ing_name,
            supermarket_section: normalize_section(ing_data[:supermarket_section])
          )
        end

        di = DishIngredient.find_or_initialize_by(dish: dish, ingredient: ingredient)
        di.suggested_quantity = ing_data[:suggested_quantity].to_s.strip.presence || "1 unidad"
        di.save!
      end

      created_map[dish_name.downcase] = dish.id
      created_map[dish.name.downcase] = dish.id
    end

    created_map
  end

  # Merges session.proposed_dishes with optional user form overrides.
  #
  # @param proposed_dishes [Array<Hash>]
  # @param dish_overrides [Hash, ActionController::Parameters, nil]
  # @return [Array<Hash>]
  def extract_dishes_to_persist(proposed_dishes, dish_overrides)
    if dish_overrides.present?
      raw_hash = dish_overrides.respond_to?(:to_unsafe_h) ? dish_overrides.to_unsafe_h : dish_overrides.to_h
      raw_hash.values.map do |d_val|
        d = d_val.with_indifferent_access
        raw_ings = (d[:ingredients] || {}).values
        {
          included: ActiveModel::Type::Boolean.new.cast(d.fetch(:included, "1")),
          name: d[:name],
          category: d[:category],
          ingredients: raw_ings.map do |i_val|
            i = i_val.with_indifferent_access
            {
              included: ActiveModel::Type::Boolean.new.cast(i.fetch(:included, "1")),
              name: i[:name],
              supermarket_section: i[:supermarket_section],
              suggested_quantity: i[:suggested_quantity]
            }
          end
        }
      end
    else
      Array(proposed_dishes).map do |d|
        {
          included: true,
          name: d["name"] || d[:name],
          category: d["category"] || d[:category],
          ingredients: Array(d["ingredients"] || d[:ingredients]).map do |i|
            {
              included: true,
              name: i["name"] || i[:name],
              supermarket_section: i["supermarket_section"] || i[:supermarket_section],
              suggested_quantity: i["suggested_quantity"] || i[:suggested_quantity]
            }
          end
        }
      end
    end
  end

  # Resolves lunch_new_dish_name and dinner_new_dish_name in proposed_plan to actual Dish IDs.
  #
  # @param proposed_plan [Array<Hash>]
  # @param created_dishes_by_name [Hash<String, Integer>]
  # @return [Array<Hash>]
  def resolve_plan_dish_ids(proposed_plan, created_dishes_by_name)
    Array(proposed_plan).map do |entry|
      lunch_id = entry["lunch_dish_id"] || entry[:lunch_dish_id]
      dinner_id = entry["dinner_dish_id"] || entry[:dinner_dish_id]
      lunch_new = (entry["lunch_new_dish_name"] || entry[:lunch_new_dish_name]).to_s.strip
      dinner_new = (entry["dinner_new_dish_name"] || entry[:dinner_new_dish_name]).to_s.strip

      if lunch_id.blank? && lunch_new.present?
        lunch_id = created_dishes_by_name[lunch_new.downcase] || Dish.where("LOWER(name) = ?", lunch_new.downcase).pick(:id)
      end

      if dinner_id.blank? && dinner_new.present?
        dinner_id = created_dishes_by_name[dinner_new.downcase] || Dish.where("LOWER(name) = ?", dinner_new.downcase).pick(:id)
      end

      {
        "day" => entry["day"] || entry[:day],
        "lunch_dish_id" => lunch_id,
        "dinner_dish_id" => dinner_id
      }
    end
  end

  # Normalizes a raw category string to one of Dish::CATEGORIES.
  #
  # @param raw_category [String, nil]
  # @return [String]
  def normalize_category(raw_category)
    key = raw_category.to_s.strip
    return key if Dish::CATEGORIES.include?(key)

    CATEGORY_MAP.fetch(key.downcase, "Lunch")
  end

  # Normalizes a raw supermarket section string to one of Ingredient::SECTIONS.
  #
  # @param raw_section [String, nil]
  # @return [String]
  def normalize_section(raw_section)
    sec = raw_section.to_s.strip
    matched = Ingredient::SECTIONS.find { |s| s.casecmp?(sec) }
    matched || "Otros"
  end
end
