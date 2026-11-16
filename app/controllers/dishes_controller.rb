# Handles request routing and parameters for the Dish model.
# Supports CRUD operations, inline ingredient creation, and AI ingredient suggestions.
class DishesController < ApplicationController
  before_action :set_dish, only: [ :show, :edit, :update, :destroy ]
  before_action :set_ingredients, only: [ :new, :edit, :create, :update ]

  rate_limit to: 15, within: 5.minutes, only: :suggest_ingredients, with: -> {
    render json: { error: t("ai_chat_messages.controller.rate_limited") }, status: :too_many_requests
  }

  # GET /dishes
  # Lists all dishes ordered by name.
  # @return [void]
  def index
    @dishes = Dish.includes(:ingredients).order(:name)
  end

  # GET /dishes/:id
  # Displays details for a single dish.
  # @return [void]
  def show
  end

  # GET /dishes/new
  # Initializes a new Dish record.
  # @return [void]
  def new
    @dish = Dish.new
    @dish.dish_ingredients.build
  end

  # GET /dishes/:id/edit
  # Renders the form to edit an existing dish.
  # @return [void]
  def edit
  end

  # POST /dishes
  # Creates a new Dish record with the given parameters, automatically creating any inline new ingredients.
  # @return [void]
  def create
    @dish = Dish.new
    if save_dish_with_inline_ingredients!(@dish)
      redirect_to dishes_path, notice: t("dishes.controller.created")
    else
      set_ingredients
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /dishes/:id
  # Updates an existing Dish record with the given parameters, automatically creating any inline new ingredients.
  # @return [void]
  def update
    if save_dish_with_inline_ingredients!(@dish)
      redirect_to dishes_path, notice: t("dishes.controller.updated")
    else
      set_ingredients
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /dishes/:id
  # Destroys a Dish record.
  # @return [void]
  def destroy
    @dish.destroy!
    redirect_to dishes_path, notice: t("dishes.controller.deleted")
  end

  # POST /dishes/suggest_ingredients
  # Queries Gemini to suggest a category and ingredient list for a given dish name.
  # @return [void]
  def suggest_ingredients
    dish_name = params.expect(:dish_name).to_s.strip
    if dish_name.blank?
      render json: { error: t("dishes.form.ai_blank_name") }, status: :unprocessable_content
      return
    end

    suggestion = AiCopilotService.new.suggest_ingredients_for_dish(dish_name)
    render json: suggestion, status: :ok
  rescue ActionController::ParameterMissing
    render json: { error: t("dishes.form.ai_blank_name") }, status: :unprocessable_content
  rescue GeminiClient::ConfigurationError
    render json: { error: t("ai_chat_messages.controller.missing_api_key") }, status: :unprocessable_content
  rescue GeminiClient::ApiError
    render json: { error: t("ai_chat_messages.controller.api_error") }, status: :bad_gateway
  end

  private

  # Set the @dish instance variable based on request id.
  # @return [Dish] the retrieved dish
  # @raise [ActiveRecord::RecordNotFound] if the dish does not exist
  def set_dish
    @dish = Dish.find(params[:id])
  end

  # Load all ingredients ordered by name for form options.
  # @return [ActiveRecord::Relation<Ingredient>]
  def set_ingredients
    @ingredients = Ingredient.all.order(:name)
  end

  # Permit and validate strong parameters for Dish, including optional inline new ingredient fields.
  # @return [ActionController::Parameters]
  def dish_params
    params.expect(
      dish: [
        :name,
        :category,
        { categories: [] },
        { dish_ingredients_attributes: [
          :id,
          :ingredient_id,
          :ingredient_name,
          :supermarket_section,
          :suggested_quantity,
          :_destroy
        ] }
      ]
    )
  end

  # Resolves any inline new ingredients inside a transaction and saves the Dish.
  #
  # @param dish [Dish]
  # @return [Boolean]
  def save_dish_with_inline_ingredients!(dish)
    permitted = dish_params.to_h.with_indifferent_access
    raw_nested = permitted[:dish_ingredients_attributes]

    saved = false
    ActiveRecord::Base.transaction do
      if raw_nested.is_a?(Hash) || raw_nested.is_a?(Array)
        entries = raw_nested.is_a?(Hash) ? raw_nested.values : raw_nested
        normalized_nested = entries.filter_map do |entry|
          row = entry.with_indifferent_access
          ing_id = row[:ingredient_id].presence
          ing_name = row[:ingredient_name].to_s.strip

          if ing_id.blank? && ing_name.present? && !ActiveModel::Type::Boolean.new.cast(row[:_destroy])
            sec = Ingredient::SECTIONS.find { |s| s.casecmp?(row[:supermarket_section].to_s.strip) } || "Otros"
            ingredient = Ingredient.where("LOWER(name) = ?", ing_name.downcase).first ||
                         Ingredient.create!(name: ing_name, supermarket_section: sec)
            ing_id = ingredient.id
          end

          {
            id: row[:id],
            ingredient_id: ing_id,
            suggested_quantity: row[:suggested_quantity],
            _destroy: row[:_destroy]
          }
        end
        permitted[:dish_ingredients_attributes] = normalized_nested
      end

      if dish_params[:categories].present? || params.dig(:dish, :categories).is_a?(Array)
        cleaned_cats = Array(permitted[:categories]).map { |c| c.to_s.strip }.reject(&:blank?).uniq
        permitted[:categories] = cleaned_cats
        permitted[:category] = cleaned_cats.first
      end

      dish.assign_attributes(permitted)
      if dish.save
        saved = true
      else
        raise ActiveRecord::Rollback
      end
    end
    saved
  rescue ActiveRecord::RecordInvalid
    false
  end
end
