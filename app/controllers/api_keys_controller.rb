# Handles requests for managing API keys in the settings page.
class ApiKeysController < ApplicationController
  before_action :set_api_key, only: [:update, :destroy]

  # GET /api_keys
  # Lists all API keys.
  # @return [void]
  def index
    @api_keys = ApiKey.all.order(created_at: :desc)
    @api_key = ApiKey.new
  end

  # POST /api_keys
  # Creates a new API Key record.
  # @return [void]
  def create
    @api_key = ApiKey.new(api_key_params)

    if @api_key.save
      # Store the plain token temporarily in the flash session so the user can copy it once
      flash[:plain_token] = @api_key.token
      redirect_to post_action_redirect_path, notice: t('api_keys.controller.created')
    else
      @api_keys = ApiKey.all.order(created_at: :desc)
      render_validation_error
    end
  end

  # PATCH/PUT /api_keys/:id
  # Toggles/updates the API key parameters (like active status).
  # @return [void]
  def update
    if @api_key.update(api_key_params)
      redirect_to post_action_redirect_path, notice: t('api_keys.controller.updated', default: "Estado actualizado.")
    else
      @api_keys = ApiKey.all.order(created_at: :desc)
      render_validation_error
    end
  end

  # DELETE /api_keys/:id
  # Revokes/deletes the API Key.
  # @return [void]
  def destroy
    @api_key.destroy!
    redirect_to post_action_redirect_path, notice: t('api_keys.controller.revoked')
  end

  private

  # Determines where to redirect after creating, updating, or revoking a key.
  # @return [String]
  def post_action_redirect_path
    params[:return_to] == "settings" ? settings_path(tab: "integrations") : api_keys_path
  end

  # Renders the originating view with HTTP 422 when validation fails.
  # @return [void]
  def render_validation_error
    if params[:return_to] == "settings"
      @active_tab = "integrations"
      @histories = MealPlanHistory.order(year: :desc, week_number: :desc)
      @return_to = "settings"
      render "settings/show", status: :unprocessable_entity
    else
      render :index, status: :unprocessable_entity
    end
  end

  # Set the API key from request id.
  # @return [ApiKey] the api key
  def set_api_key
    @api_key = ApiKey.find(params[:id])
  end

  # Permitted parameters for API keys.
  # @return [ActionController::Parameters]
  def api_key_params
    params.expect(api_key: [:name, :active])
  end
end
