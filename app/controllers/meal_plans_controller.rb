# Handles dashboard and calendar actions for MealPlan planning.
class MealPlansController < ApplicationController
  # GET /
  # GET /meal_plans
  # Renders the dashboard featuring the weekly calendar, shopping list, and Gemini AI Copilot chat.
  # @return [void]
  def index
    # Load all meal plans in order of the week (eager loading associations to prevent N+1 queries)
    days = MealPlan::DAYS_OF_WEEK
    existing_plans = MealPlan.includes(:lunch_dish, :dinner_dish).index_by(&:day_of_week)
    @meal_plans = days.each_with_object({}) do |day, hash|
      hash[day] = existing_plans[day] || MealPlan.new(day_of_week: day)
    end

    # Load available dishes for selecting in the form and resolving preview names in O(1)
    @dishes = Dish.all.order(:name)
    @dishes_by_id = @dishes.index_by(&:id)

    # Load persisted AI chat sessions and resolve the active session
    @chat_sessions = AiChatSession.includes(:ai_chat_messages).order(updated_at: :desc).to_a
    @active_chat_session = resolve_active_chat_session

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
      MealPlanHistory.record_current_week!(target_date: Date.current, source: "manual")
      redirect_to root_path, notice: t("meal_plans.controller.updated", day: day_translated)
    else
      redirect_to root_path, alert: t("meal_plans.controller.error_update", day: day_translated, errors: plan.errors.full_messages.join(", "))
    end
  end

  private

  # Finds the currently selected AiChatSession or creates a default initial session.
  #
  # @return [AiChatSession]
  def resolve_active_chat_session
    if session[:active_ai_chat_session_id].present?
      found = @chat_sessions.find { |s| s.id == session[:active_ai_chat_session_id].to_i }
      return found if found
    end

    return @chat_sessions.first if @chat_sessions.any?

    created = AiChatSession.create!(
      title: "#{t('ai_chat_sessions.default_title')} (#{Time.current.strftime('%d/%m')})",
      parameters: AiChatSession::DEFAULT_PARAMETERS
    )
    @chat_sessions = [ created ]
    session[:active_ai_chat_session_id] = created.id
    created
  end
end
