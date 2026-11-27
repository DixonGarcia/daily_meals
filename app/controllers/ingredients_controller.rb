# Handles request routing and parameters for the Ingredient model.
# Supports CRUD operations for managing ingredients in the system.
class IngredientsController < ApplicationController
  before_action :set_ingredient, only: [ :show, :edit, :update, :destroy ]

  # GET /ingredients
  # Lists all ingredients ordered by name.
  # @return [void]
  def index
    @ingredients = Ingredient.order(:name)
  end

  # GET /ingredients/:id
  # Displays details for a single ingredient.
  # @return [void]
  def show
  end

  # GET /ingredients/new
  # Initializes a new Ingredient record.
  # @return [void]
  def new
    @ingredient = Ingredient.new
  end

  # GET /ingredients/:id/edit
  # Renders the form to edit an existing ingredient.
  # @return [void]
  def edit
  end

  # POST /ingredients
  # Creates a new Ingredient record with the given parameters.
  # @return [void]
  def create
    @ingredient = Ingredient.new(ingredient_params)
    if @ingredient.save
      redirect_to ingredients_path, notice: t("ingredients.controller.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /ingredients/:id
  # Updates an existing Ingredient record with the given parameters.
  # @return [void]
  def update
    if @ingredient.update(ingredient_params)
      redirect_to ingredients_path, notice: t("ingredients.controller.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /ingredients/:id
  # Destroys an Ingredient record.
  # @return [void]
  def destroy
    @ingredient.destroy!
    redirect_to ingredients_path, notice: t("ingredients.controller.deleted")
  end

  private

  # Set the @ingredient instance variable based on request id.
  # @return [Ingredient] the retrieved ingredient
  # @raise [ActiveRecord::RecordNotFound] if the ingredient does not exist
  def set_ingredient
    @ingredient = Ingredient.find(params.expect(:id))
  end

  # Permit and validate strong parameters for Ingredient.
  # @return [ActionController::Parameters]
  def ingredient_params
    params.expect(ingredient: [ :name, :supermarket_section, :pantry_staple ])
  end
end
