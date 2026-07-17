require 'rails_helper'

RSpec.describe MealPlan, type: :model do
  let(:dish_1) { Dish.create!(name: 'Carne molida con papas', category: 'Lunch') }
  let(:dish_2) { Dish.create!(name: 'Pasta boloñesa', category: 'Lunch') }

  describe 'validations' do
    it 'is valid with valid attributes' do
      plan = MealPlan.new(day_of_week: 'Monday', lunch_dish: dish_1, dinner_dish: dish_2)
      expect(plan).to be_valid
    end

    it 'is valid with no dishes planned' do
      plan = MealPlan.new(day_of_week: 'Tuesday', lunch_dish: nil, dinner_dish: nil)
      expect(plan).to be_valid
    end

    it 'is invalid without a day_of_week' do
      plan = MealPlan.new(day_of_week: nil, lunch_dish: dish_1)
      expect(plan).not_to be_valid
    end

    it 'is invalid with an invalid day_of_week' do
      plan = MealPlan.new(day_of_week: 'Funday', lunch_dish: dish_1)
      expect(plan).not_to be_valid
    end

    it 'enforces uniqueness of day_of_week' do
      MealPlan.create!(day_of_week: 'Monday', lunch_dish: dish_1)
      duplicate = MealPlan.new(day_of_week: 'Monday', dinner_dish: dish_2)
      expect(duplicate).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to lunch_dish' do
      association = described_class.reflect_on_association(:lunch_dish)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:class_name]).to eq 'Dish'
      expect(association.options[:optional]).to be_truthy
    end

    it 'belongs to dinner_dish' do
      association = described_class.reflect_on_association(:dinner_dish)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:class_name]).to eq 'Dish'
      expect(association.options[:optional]).to be_truthy
    end
  end
end
