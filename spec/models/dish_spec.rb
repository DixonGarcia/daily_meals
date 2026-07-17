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
