# API controller to expose and import dishes catalog programmatically.
class Api::V1::DishesController < Api::V1::BaseController
  # GET /api/v1/dishes
  # Returns the list of dishes with their categories and ingredients.
  # @return [void]
  def index
    dishes = Dish.includes(:ingredients).order(:name)
    render json: dishes.as_json(include: { ingredients: { only: [ :id, :name, :supermarket_section ] } })
  end

  # POST /api/v1/dishes/import
  # Imports a catalog of dishes and ingredients atomically inside a transaction.
  # @return [void]
  def import
    dishes_payload = params.expect(:dishes)

    success = true
    ActiveRecord::Base.transaction do
      dishes_payload.each do |dish_data|
        dish = Dish.find_or_initialize_by(name: dish_data[:name])
        if dish_data[:categories].is_a?(Array)
          dish.categories = dish_data[:categories]
        else
          dish.category = dish_data[:category]
        end

        unless dish.save
          success = false
          raise ActiveRecord::Rollback
        end

        if dish_data[:ingredients].is_a?(Array)
          dish_data[:ingredients].each do |ing_data|
            ingredient = Ingredient.find_or_initialize_by(name: ing_data[:name])
            ingredient.supermarket_section = ing_data[:supermarket_section]

            unless ingredient.save
              success = false
              raise ActiveRecord::Rollback
            end

            di = DishIngredient.find_or_initialize_by(dish: dish, ingredient: ingredient)
            di.suggested_quantity = ing_data[:suggested_quantity]

            unless di.save
              success = false
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end

    if success
      render json: { status: "success" }, status: :ok
    else
      render json: { error: "Failed to import dishes catalog" }, status: :unprocessable_entity
    end
  end
end
