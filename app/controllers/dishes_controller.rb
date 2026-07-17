class DishesController < ApplicationController
  before_action :set_dish, only: [:show, :edit, :update, :destroy]
  before_action :set_ingredients, only: [:new, :edit, :create, :update]

  def index
    @dishes = Dish.all.order(:name)
  end

  def show
  end

  def new
    @dish = Dish.new
    # Pre-build some empty associations or let the UI handle it
    @dish.dish_ingredients.build
  end

  def edit
  end

  def create
    @dish = Dish.new(dish_params)
    if @dish.save
      redirect_to dishes_path, notice: 'Dish was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @dish.update(dish_params)
      redirect_to dishes_path, notice: 'Dish was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @dish.destroy
    redirect_to dishes_path, notice: 'Dish was successfully deleted.'
  end

  private

  def set_dish
    @dish = Dish.find(params[:id])
  end

  def set_ingredients
    @ingredients = Ingredient.all.order(:name)
  end

  def dish_params
    params.require(:dish).permit(
      :name,
      :category,
      dish_ingredients_attributes: [:id, :ingredient_id, :suggested_quantity, :_destroy]
    )
  end
end
