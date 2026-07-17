require 'rails_helper'

RSpec.describe ShoppingListGenerator do
  let!(:beef) { Ingredient.create!(name: 'Carne molida', supermarket_section: 'Carnicería') }
  let!(:potato) { Ingredient.create!(name: 'Papa', supermarket_section: 'Verdulería') }
  let!(:tomato_sauce) { Ingredient.create!(name: 'Salsa de tomate', supermarket_section: 'Víveres') }

  let!(:dish_1) { Dish.create!(name: 'Carne molida con papas', category: 'Lunch') }
  let!(:dish_2) { Dish.create!(name: 'Pasta boloñesa', category: 'Lunch') }

  before do
    DishIngredient.create!(dish: dish_1, ingredient: beef, suggested_quantity: '500g')
    DishIngredient.create!(dish: dish_1, ingredient: potato, suggested_quantity: '1 kg')

    DishIngredient.create!(dish: dish_2, ingredient: beef, suggested_quantity: '500g')
    DishIngredient.create!(dish: dish_2, ingredient: tomato_sauce, suggested_quantity: '1 lata')
  end

  describe '#generate' do
    context 'when there are no meal plans' do
      it 'returns an empty list' do
        result = ShoppingListGenerator.new.generate
        expect(result).to be_empty
      end
    end

    context 'when there are active meal plans' do
      before do
        MealPlan.create!(day_of_week: 'Monday', lunch_dish: dish_1, dinner_dish: dish_2)
      end

      it 'groups ingredients by supermarket section' do
        result = ShoppingListGenerator.new.generate

        expect(result.keys).to contain_exactly('Carnicería', 'Verdulería', 'Víveres')
      end

      it 'consolidates duplicate ingredients matching same unit' do
        result = ShoppingListGenerator.new.generate

        beef_item = result['Carnicería'].find { |item| item[:ingredient].name == 'Carne molida' }
        expect(beef_item[:quantity]).to eq('1000g')
      end

      it 'lists non-duplicate ingredients' do
        result = ShoppingListGenerator.new.generate

        potato_item = result['Verdulería'].find { |item| item[:ingredient].name == 'Papa' }
        expect(potato_item[:quantity]).to eq('1 kg')

        sauce_item = result['Víveres'].find { |item| item[:ingredient].name == 'Salsa de tomate' }
        expect(sauce_item[:quantity]).to eq('1 lata')
      end
    end

    context 'when duplicate ingredients have different units' do
      before do
        # Create another dish with beef but different unit
        dish_3 = Dish.create!(name: 'Tacos', category: 'Dinner')
        DishIngredient.create!(dish: dish_3, ingredient: beef, suggested_quantity: '2 paquetes')
        MealPlan.create!(day_of_week: 'Monday', lunch_dish: dish_1)
        MealPlan.create!(day_of_week: 'Tuesday', lunch_dish: dish_3)
      end

      it 'concatenates the different units' do
        result = ShoppingListGenerator.new.generate

        beef_item = result['Carnicería'].find { |item| item[:ingredient].name == 'Carne molida' }
        expect(beef_item[:quantity]).to eq('500g + 2 paquetes')
      end
    end
  end
end
