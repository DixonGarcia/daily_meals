# Handles request routing and parameters for the Dish model.
# Supports CRUD operations for managing dishes in the system.
class DishesController < ApplicationController
  before_action :set_dish, only: [:show, :edit, :update, :destroy]
  before_action :set_ingredients, only: [:new, :edit, :create, :update]

  # GET /dishes
  # Lists all dishes ordered by name.
  # @return [void]
  def index
    @dishes = Dish.all.order(:name)
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
    # Pre-build some empty associations or let the UI handle it
    @dish.dish_ingredients.build
  end

  # GET /dishes/:id/edit
  # Renders the form to edit an existing dish.
  # @return [void]
  def edit
  end

  # POST /dishes
  # Creates a new Dish record with the given parameters.
  # @return [void]
  def create
    @dish = Dish.new(dish_params)
    if @dish.save
      redirect_to dishes_path, notice: t('dishes.controller.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /dishes/:id
  # Updates an existing Dish record with the given parameters.
  # @return [void]
  def update
    if @dish.update(dish_params)
      redirect_to dishes_path, notice: t('dishes.controller.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /dishes/:id
  # Destroys a Dish record.
  # @return [void]
  def destroy
    @dish.destroy!
    redirect_to dishes_path, notice: t('dishes.controller.deleted')
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

  # Permit and validate strong parameters for Dish.
  # @return [ActionController::Parameters]
  def dish_params
    params.expect(
      dish: [
        :name,
        :category,
        dish_ingredients_attributes: [:id, :ingredient_id, :suggested_quantity, :_destroy]
      ]
    )
  end
end
