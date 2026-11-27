# Consolidates secondary configuration views (Household Diet Profile, Weekly Meal History, and API Integrations).
class SettingsController < ApplicationController
  # Allowed tab identifiers for /settings.
  VALID_TABS = %w[diet history integrations].freeze

  # GET /settings
  # Renders the consolidated settings view with the requested active tab.
  #
  # @return [void]
  def show
    requested_tab = params[:tab].to_s
    @active_tab = VALID_TABS.include?(requested_tab) ? requested_tab : "history"
    load_settings_collections
  end

  # PATCH /settings/household
  # Updates the singleton HouseholdSetting record (servings_multiplier and diet_guidelines).
  #
  # @return [void]
  def update_household
    @household_setting = HouseholdSetting.current

    if @household_setting.update(household_setting_params)
      redirect_to settings_path(tab: "diet"), notice: t("settings.diet.saved_notice")
    else
      @active_tab = "diet"
      load_settings_collections(preserve_household: true)
      render :show, status: :unprocessable_entity
    end
  end

  private

  # Loads collections required by the tabbed settings view.
  #
  # @param preserve_household [Boolean] Keep @household_setting with validation errors when re-rendering.
  # @return [void]
  def load_settings_collections(preserve_household: false)
    @household_setting ||= HouseholdSetting.current unless preserve_household
    @histories = MealPlanHistory.order(year: :desc, week_number: :desc)
    @api_keys = ApiKey.order(created_at: :desc)
    @api_key = ApiKey.new
    @return_to = "settings"
  end

  # Permits strong parameters for HouseholdSetting using Rails 8 params.expect.
  #
  # @return [ActionController::Parameters]
  def household_setting_params
    params.expect(household_setting: [ :servings_multiplier, :diet_guidelines ])
  end
end
