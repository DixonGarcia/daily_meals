# Handles dashboard and calendar actions for MealPlan planning.
class MealPlansController < ApplicationController
  allow_guest_access only: :index

  # GET /
  # GET /meal_plans
  # Renders the dashboard featuring the daily/weekly calendar, shopping list, and (when authenticated) Gemini AI Copilot chat.
  # @return [void]
  def index
    days = MealPlan::DAYS_OF_WEEK
    existing_plans = MealPlan.includes(
      lunch_dish: { dish_ingredients: :ingredient },
      dinner_dish: { dish_ingredients: :ingredient }
    ).index_by(&:day_of_week)

    @meal_plans = days.each_with_object({}) do |day, hash|
      hash[day] = existing_plans[day] || MealPlan.new(day_of_week: day)
    end

    @view_mode = params[:view] == "week" ? "week" : "day"
    @today_key = Time.zone.today.strftime("%A")
    @selected_day = days.include?(params[:day].to_s) ? params[:day].to_s : @today_key
    @tomorrow_key = MealPlan.next_day_for(@selected_day)
    @tomorrow_plan = @meal_plans[@tomorrow_key]
    @tomorrow_defrost_items = @tomorrow_plan.defrost_ingredient_names

    @household_setting = HouseholdSetting.current_or_default
    stored_servings = cookies[:shopping_servings].to_i
    @servings = stored_servings.between?(1, ShoppingListGenerator::MAX_SERVINGS) ? stored_servings : @household_setting.servings_multiplier
    @shopping_summary = ShoppingListGenerator.new(servings: @servings, meal_plans: existing_plans.values).generate_grouped

    return unless authenticated?

    @dishes = Dish.order(:name)
    @dishes_by_id = @dishes.index_by(&:id)
    @active_chat_session = resolve_active_chat_session
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
    redirect_params = { view: params[:view].presence, day: params[:day].presence }.compact

    if plan.save
      MealPlanHistory.record_current_week!(target_date: Date.current, source: "manual")
      redirect_to root_path(redirect_params), notice: t("meal_plans.controller.updated", day: day_translated)
    else
      redirect_to root_path(redirect_params), alert: t("meal_plans.controller.error_update", day: day_translated, errors: plan.errors.full_messages.join(", "))
    end
  end

  # PATCH /meal_plans/update_week
  # Atomically updates lunch and dinner dish selections across all submitted days of the week
  # so editing multiple days in week view never loses unsaved selections on other cards.
  #
  # @return [void]
  def update_week
    days_schema = MealPlan::DAYS_OF_WEEK.each_with_object({}) { |day, hash| hash[day.to_sym] = [ :lunch_dish_id, :dinner_dish_id ] }
    days_params = params.expect(days: [ days_schema ])

    ActiveRecord::Base.transaction do
      MealPlan::DAYS_OF_WEEK.each do |day|
        day_attrs = days_params[day]
        next unless day_attrs

        plan = MealPlan.find_or_initialize_by(day_of_week: day)
        plan.lunch_dish_id = day_attrs[:lunch_dish_id].presence
        plan.dinner_dish_id = day_attrs[:dinner_dish_id].presence
        plan.save!
      end

      MealPlanHistory.record_current_week!(target_date: Date.current, source: "manual")
    end

    redirect_to root_path(view: "week"), notice: t("meal_plans.controller.week_updated")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path(view: "week"), alert: t("meal_plans.controller.error_week_update", errors: e.record.errors.full_messages.join(", "))
  end

  private

  # Finds the single active AiChatSession or creates a default initial session.
  #
  # @return [AiChatSession]
  def resolve_active_chat_session
    if session[:active_ai_chat_session_id].present?
      found = AiChatSession.includes(:ai_chat_messages).find_by(id: session[:active_ai_chat_session_id])
      return found if found
    end

    latest = AiChatSession.includes(:ai_chat_messages).order(updated_at: :desc).first
    return latest if latest

    created = AiChatSession.create!(
      title: "#{t('ai_chat_sessions.default_title')} (#{Time.current.strftime('%d/%m')})",
      parameters: AiChatSession::DEFAULT_PARAMETERS
    )
    session[:active_ai_chat_session_id] = created.id
    created
  end
end
