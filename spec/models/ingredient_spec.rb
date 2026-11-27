require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      ingredient = Ingredient.new(name: 'Carne molida', supermarket_section: 'Carnicería')
      expect(ingredient).to be_valid
    end

    it 'accepts Charcutería as a valid supermarket_section' do
      ingredient = Ingredient.new(name: 'Queso blanco', supermarket_section: 'Charcutería')
      expect(ingredient).to be_valid
    end

    it 'defaults pantry_staple to false and supports positive predicate pantry_staple?' do
      fresh = Ingredient.create!(name: 'Papa', supermarket_section: 'Verdulería')
      staple = Ingredient.create!(name: 'Aceite de oliva', supermarket_section: 'Despensa', pantry_staple: true)

      expect(fresh.pantry_staple?).to be(false)
      expect(staple.pantry_staple?).to be(true)
    end

    it 'orders SECTIONS in canonical Venezuelan market stop sequence' do
      expect(Ingredient::SECTIONS.first(3)).to eq([ 'Verdulería', 'Carnicería', 'Charcutería' ])
    end

    it 'is invalid without a name' do
      ingredient = Ingredient.new(name: nil, supermarket_section: 'Carnicería')
      expect(ingredient).not_to be_valid
    end

    it 'is invalid without a supermarket_section' do
      ingredient = Ingredient.new(name: 'Carne molida', supermarket_section: nil)
      expect(ingredient).not_to be_valid
    end

    it 'enforces uniqueness of name' do
      Ingredient.create!(name: 'Carne molida', supermarket_section: 'Carnicería')
      duplicate = Ingredient.new(name: 'Carne molida', supermarket_section: 'Víveres')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'associations' do
    it 'has many dish_ingredients' do
      association = described_class.reflect_on_association(:dish_ingredients)
      expect(association.macro).to eq :has_many
    end

    it 'has many dishes through dish_ingredients' do
      association = described_class.reflect_on_association(:dishes)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :dish_ingredients
    end
  end
end
