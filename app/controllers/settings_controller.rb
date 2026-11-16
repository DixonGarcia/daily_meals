# Consolidates secondary configuration views (Weekly Meal History and Integrations/API Keys).
class SettingsController < ApplicationController
  VALID_TABS = %w[history integrations].freeze

  # GET /settings
  # Renders the consolidated settings view with the requested active tab.
  #
  # @return [void]
  def show
    requested_tab = params[:tab].to_s
    @active_tab = VALID_TABS.include?(requested_tab) ? requested_tab : "history"
    @histories = MealPlanHistory.order(year: :desc, week_number: :desc)
    @api_keys = ApiKey.order(created_at: :desc)
    @api_key = ApiKey.new
    @return_to = "settings"
  end
end
