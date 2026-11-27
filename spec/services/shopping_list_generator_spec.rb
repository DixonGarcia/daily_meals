require 'rails_helper'

RSpec.describe ShoppingListGenerator do
  let!(:beef) { Ingredient.create!(name: 'Carne molida', supermarket_section: 'Carnicería') }
  let!(:chicken) { Ingredient.create!(name: 'Pechuga de pollo', supermarket_section: 'Carnicería') }
  let!(:potato) { Ingredient.create!(name: 'Papa', supermarket_section: 'Verdulería') }
  let!(:avocado) { Ingredient.create!(name: 'Aguacate', supermarket_section: 'Verdulería') }
  let!(:cheese) { Ingredient.create!(name: 'Queso blanco', supermarket_section: 'Charcutería') }
  let!(:olive_oil) { Ingredient.create!(name: 'Aceite de oliva', supermarket_section: 'Despensa', pantry_staple: true) }
  let!(:tomato_sauce) { Ingredient.create!(name: 'Salsa de tomate', supermarket_section: 'Víveres') }

  let!(:dish_1) { Dish.create!(name: 'Carne molida con papas', category: 'Lunch') }
  let!(:dish_2) { Dish.create!(name: 'Pasta boloñesa', category: 'Lunch') }
  let!(:meal_prep_dish) { Dish.create!(name: 'Pollo a la plancha', category: 'Lunch') }

  before do
    DishIngredient.create!(dish: dish_1, ingredient: beef, suggested_quantity: '500g')
    DishIngredient.create!(dish: dish_1, ingredient: potato, suggested_quantity: '1 kg')

    DishIngredient.create!(dish: dish_2, ingredient: beef, suggested_quantity: '500g')
    DishIngredient.create!(dish: dish_2, ingredient: tomato_sauce, suggested_quantity: '1 lata')

    DishIngredient.create!(dish: meal_prep_dish, ingredient: chicken, suggested_quantity: '90g')
    DishIngredient.create!(dish: meal_prep_dish, ingredient: olive_oil, suggested_quantity: '15ml')
  end

  describe '#generate' do
    context 'when there are no meal plans' do
      it 'returns an empty hash' do
        result = described_class.new.generate
        expect(result).to be_empty
      end
    end

    context 'when dishes are repeated across multiple days' do
      before do
        MealPlan.create!(day_of_week: 'Monday', lunch_dish: meal_prep_dish)
        MealPlan.create!(day_of_week: 'Tuesday', lunch_dish: meal_prep_dish)
        MealPlan.create!(day_of_week: 'Wednesday', lunch_dish: meal_prep_dish)
      end

      it 'multiplies ingredient quantities by dish occurrence count and servings' do
        result = described_class.new(servings: 2).generate

        chicken_item = result['Carnicería'].find { |item| item[:ingredient].name == 'Pechuga de pollo' }
        expect(chicken_item[:quantity]).to eq('540g')
        expect(chicken_item[:dishes]).to eq([ { name: 'Pollo a la plancha', count: 3 } ])

        oil_item = result['Despensa'].find { |item| item[:ingredient].name == 'Aceite de oliva' }
        expect(oil_item[:quantity]).to eq('90ml')
        expect(oil_item[:pantry_staple]).to be(true)
      end
    end

    context 'when consolidating metric weights, volumes, fractions, and Spanish plurals' do
      let!(:dish_a) { Dish.create!(name: 'Plato A', category: 'Lunch') }
      let!(:dish_b) { Dish.create!(name: 'Plato B', category: 'Dinner') }

      before do
        DishIngredient.create!(dish: dish_a, ingredient: potato, suggested_quantity: '600g')
        DishIngredient.create!(dish: dish_b, ingredient: potato, suggested_quantity: '1/2 kg')

        DishIngredient.create!(dish: dish_a, ingredient: avocado, suggested_quantity: '1 unidad')
        DishIngredient.create!(dish: dish_b, ingredient: avocado, suggested_quantity: '2 unidades')

        DishIngredient.create!(dish: dish_a, ingredient: olive_oil, suggested_quantity: '700ml')
        DishIngredient.create!(dish: dish_b, ingredient: olive_oil, suggested_quantity: '0,5 L')

        DishIngredient.create!(dish: dish_a, ingredient: cheese, suggested_quantity: '½ paquete')
        DishIngredient.create!(dish: dish_b, ingredient: cheese, suggested_quantity: '1 1/2 paquetes')

        MealPlan.create!(day_of_week: 'Monday', lunch_dish: dish_a, dinner_dish: dish_b)
      end

      it 'normalizes grams/kg, ml/L, fractions, decimal commas, and singular/plural units' do
        result = described_class.new(servings: 1).generate

        potato_item = result['Verdulería'].find { |i| i[:ingredient] == potato }
        expect(potato_item[:quantity]).to eq('1.1 kg')

        avocado_item = result['Verdulería'].find { |i| i[:ingredient] == avocado }
        expect(avocado_item[:quantity]).to eq('3 unidades')

        oil_item = result['Despensa'].find { |i| i[:ingredient] == olive_oil }
        expect(oil_item[:quantity]).to eq('1.2 L')

        cheese_item = result['Charcutería'].find { |i| i[:ingredient] == cheese }
        expect(cheese_item[:quantity]).to eq('2 paquetes')
      end
    end

    context 'when consolidating matching weights >= 1000g' do
      before do
        MealPlan.create!(day_of_week: 'Monday', lunch_dish: dish_1, dinner_dish: dish_2)
      end

      it 'promotes 1000g to 1 kg and orders sections canonically' do
        result = described_class.new(servings: 1).generate

        expect(result.keys).to eq([ 'Verdulería', 'Carnicería', 'Víveres' ])

        beef_item = result['Carnicería'].find { |item| item[:ingredient].name == 'Carne molida' }
        expect(beef_item[:quantity]).to eq('1 kg')

        sauce_item = result['Víveres'].find { |item| item[:ingredient].name == 'Salsa de tomate' }
        expect(sauce_item[:quantity]).to eq('1 lata')
      end
    end

    context 'when duplicate ingredients have incompatible units' do
      before do
        dish_3 = Dish.create!(name: 'Tacos', category: 'Dinner')
        DishIngredient.create!(dish: dish_3, ingredient: beef, suggested_quantity: '2 paquetes')
        MealPlan.create!(day_of_week: 'Monday', lunch_dish: dish_1)
        MealPlan.create!(day_of_week: 'Tuesday', lunch_dish: dish_3)
      end

      it 'concatenates incompatible units cleanly' do
        result = described_class.new(servings: 1).generate

        beef_item = result['Carnicería'].find { |item| item[:ingredient].name == 'Carne molida' }
        expect(beef_item[:quantity]).to eq('500g + 2 paquetes')
      end
    end
  end

  describe '#generate_grouped' do
    before do
      dish_charc = Dish.create!(name: 'Plato con queso', category: 'Dinner')
      DishIngredient.create!(dish: dish_charc, ingredient: cheese, suggested_quantity: '150g')
      DishIngredient.create!(dish: dish_charc, ingredient: potato, suggested_quantity: '300g')

      MealPlan.create!(day_of_week: 'Monday', lunch_dish: meal_prep_dish, dinner_dish: dish_charc)
    end

    it 'separates fresh weekly items from pantry staples in canonical Venezuelan section order' do
      grouped = described_class.new(servings: 2).generate_grouped

      expect(grouped[:fresh].keys).to eq([ 'Verdulería', 'Carnicería', 'Charcutería' ])
      expect(grouped[:pantry].keys).to eq([ 'Despensa' ])
      expect(grouped[:fresh_count]).to eq(3)
      expect(grouped[:pantry_count]).to eq(1)
      expect(grouped[:total_count]).to eq(4)
    end
  end
end
