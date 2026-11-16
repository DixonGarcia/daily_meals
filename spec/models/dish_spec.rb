require 'rails_helper'

RSpec.describe Dish, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      dish = Dish.new(name: 'Pasta boloñesa', category: 'Lunch')
      expect(dish).to be_valid
    end

    it 'is invalid without a name' do
      dish = Dish.new(name: nil, category: 'Lunch')
      expect(dish).not_to be_valid
    end

    it 'is invalid without a category' do
      dish = Dish.new(name: 'Pasta boloñesa', category: nil)
      expect(dish).not_to be_valid
    end

    it 'is invalid with an invalid category' do
      dish = Dish.new(name: 'Pasta boloñesa', category: 'Dessert')
      expect(dish).not_to be_valid
    end

    it 'enforces uniqueness of name' do
      Dish.create!(name: 'Pasta boloñesa', category: 'Lunch')
      duplicate_dish = Dish.new(name: 'Pasta boloñesa', category: 'Dinner')
      expect(duplicate_dish).not_to be_valid
    end

    it 'supports multiple categories and syncs primary category' do
      dish = Dish.create!(name: 'Carne guisada', categories: [ 'Lunch', 'Dinner' ])
      expect(dish.categories).to eq([ 'Lunch', 'Dinner' ])
      expect(dish.category).to eq('Lunch')
      expect(Dish.for_category('Dinner')).to include(dish)
      expect(Dish.for_category('Lunch')).to include(dish)
    end

    it 'rejects empty or invalid categories arrays' do
      dish_empty = Dish.new(name: 'Plato sin cat', categories: [])
      expect(dish_empty).not_to be_valid

      dish_invalid = Dish.new(name: 'Plato inválido', categories: [ 'Lunch', 'Dessert' ])
      expect(dish_invalid).not_to be_valid
    end
  end

  describe 'associations' do
    it 'has many dish_ingredients' do
      association = described_class.reflect_on_association(:dish_ingredients)
      expect(association.macro).to eq :has_many
    end

    it 'has many ingredients through dish_ingredients' do
      association = described_class.reflect_on_association(:ingredients)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :dish_ingredients
    end
  end
end
