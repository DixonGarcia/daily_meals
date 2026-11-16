# Manages weekly meal plan archive snapshots inside Configuración > Historial.
class MealPlanHistoriesController < ApplicationController
  before_action :set_history, only: %i[restore destroy]

  # POST /meal_plan_histories/snapshot
  # Captures a snapshot of the active MealPlan week for the requested week offset (0 = current, 1 = next).
  #
  # @return [void]
  def snapshot
    offset_weeks = params[:week_offset].to_i == 1 ? 1 : 0
    target_date = Date.current + offset_weeks.weeks
    history = MealPlanHistory.record_current_week!(target_date: target_date, source: "manual")

    notice_msg = t("meal_plan_histories.controller.snapshot_saved", week: history.week_number, year: history.year)
    redirect_to settings_path(tab: "history"), notice: notice_msg
  end

  # POST /meal_plan_histories/:id/restore
  # Restores a historical weekly plan onto the active calendar.
  #
  # @return [void]
  def restore
    result = @history.restore_to_calendar!
    notice_msg = if result[:skipped_names].any?
      t(
        "meal_plan_histories.controller.restored_with_skips",
        week: @history.week_number,
        year: @history.year,
        skipped: result[:skipped_names].join(", ")
      )
    else
      t("meal_plan_histories.controller.restored", week: @history.week_number, year: @history.year)
    end

    redirect_to root_path, notice: notice_msg
  end

  # DELETE /meal_plan_histories/:id
  # Deletes an archived week from history.
  #
  # @return [void]
  def destroy
    @history.destroy!
    redirect_to settings_path(tab: "history"), notice: t("meal_plan_histories.controller.deleted")
  end

  private

  # Loads the target MealPlanHistory record.
  #
  # @return [void]
  def set_history
    @history = MealPlanHistory.find(params.expect(:id))
  end
end
