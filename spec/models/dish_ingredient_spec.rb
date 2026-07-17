require 'rails_helper'

RSpec.describe DishIngredient, type: :model do
  let(:dish) { Dish.create!(name: 'Pasta boloñesa', category: 'Lunch') }
  let(:ingredient) { Ingredient.create!(name: 'Salsa de tomate', supermarket_section: 'Víveres') }

  describe 'validations' do
    it 'is valid with valid attributes' do
      dish_ingredient = DishIngredient.new(dish: dish, ingredient: ingredient, suggested_quantity: '1 lata')
      expect(dish_ingredient).to be_valid
    end

    it 'is invalid without a dish' do
      dish_ingredient = DishIngredient.new(dish: nil, ingredient: ingredient, suggested_quantity: '1 lata')
      expect(dish_ingredient).not_to be_valid
    end

    it 'is invalid without an ingredient' do
      dish_ingredient = DishIngredient.new(dish: dish, ingredient: nil, suggested_quantity: '1 lata')
      expect(dish_ingredient).not_to be_valid
    end

    it 'is invalid without a suggested_quantity' do
      dish_ingredient = DishIngredient.new(dish: dish, ingredient: ingredient, suggested_quantity: nil)
      expect(dish_ingredient).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to dish' do
      association = described_class.reflect_on_association(:dish)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to ingredient' do
      association = described_class.reflect_on_association(:ingredient)
      expect(association.macro).to eq :belongs_to
    end
  end
end
