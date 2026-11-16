# Generates a consolidated shopping list based on the active MealPlans.
# Groups ingredients by their supermarket section and combines quantities with the same units.
class ShoppingListGenerator
  # Generates the consolidated shopping list from the current week's meal plans.
  #
  # @return [Hash{String => Array<Hash>}] A hash mapping supermarket sections (String)
  #   to arrays of consolidated ingredient details, e.g. { "Produce" => [{ ingredient: <Ingredient>, quantity: "500g" }] }
  def generate
    # Collect all dishes from active meal plans (eager-loading to prevent N+1 queries)
    dishes = MealPlan.includes(:lunch_dish, :dinner_dish).all.flat_map { |plan| [ plan.lunch_dish, plan.dinner_dish ] }.compact

    # Get all dish_ingredients for those dishes
    dish_ingredients = DishIngredient.where(dish: dishes).includes(:ingredient)

    # Group by ingredient
    grouped_by_ingredient = dish_ingredients.group_by(&:ingredient)

    # Build the consolidated list
    shopping_list = {}

    grouped_by_ingredient.each do |ingredient, associations|
      quantities = associations.map(&:suggested_quantity)
      consolidated_qty = consolidate_quantities(quantities)

      section = ingredient.supermarket_section
      shopping_list[section] ||= []
      shopping_list[section] << {
        ingredient: ingredient,
        quantity: consolidated_qty
      }
    end

    # Sort each section's ingredients by name for clean presentation
    shopping_list.each do |section, items|
      shopping_list[section] = items.sort_by { |item| item[:ingredient].name }
    end

    shopping_list
  end

  private

  # Parses and sums quantities sharing identical units (case-insensitive).
  # e.g., ["500g", "250g"] => "750g"
  #
  # @param quantities [Array<String>] The quantities to consolidate.
  # @return [String] The combined/summed quantity representation.
  def consolidate_quantities(quantities)
    return "" if quantities.empty?

    parsed = quantities.map do |q|
      match = q.to_s.match(/\A([\d.]+)(\s*)(.*)\z/)
      if match
        { val: match[1].to_f, spacing: match[2], unit: match[3].to_s.strip }
      else
        { val: 0.0, spacing: "", unit: q.to_s.strip }
      end
    end

    # Group by unit (case-insensitive for comparison)
    grouped = parsed.group_by { |p| p[:unit].downcase }

    parts = grouped.map do |unit_key, items|
      sum = items.map { |p| p[:val] }.sum
      # Find original casing of unit and spacing
      original_unit = items.map { |p| p[:unit] }.find(&:present?) || ""
      spacing = items.map { |p| p[:spacing] }.find { |s| !s.nil? } || ""

      if sum > 0
        formatted_sum = sum % 1 == 0 ? sum.to_i : sum
        "#{formatted_sum}#{spacing}#{original_unit}"
      else
        items.map { |p| p[:unit] }.uniq.join(" + ")
      end
    end

    parts.join(" + ")
  end
end
