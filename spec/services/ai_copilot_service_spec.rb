require 'rails_helper'

RSpec.describe AiCopilotService do
  let!(:dish_1) { Dish.create!(name: 'Carne molida con papas', category: 'Lunch') }
  let!(:dish_2) { Dish.create!(name: 'Shawarma de bisteck', category: 'Dinner') }

  describe '#export_catalog' do
    it 'formats dishes catalog and restrictions into JSON structure' do
      restrictions = 'Plan Monday to Friday'
      exporter = AiCopilotService.new
      result = exporter.export_catalog(restrictions)

      expect(result).to have_key(:dish_catalog)
      expect(result[:restrictions]).to eq(restrictions)

      catalog = result[:dish_catalog]
      expect(catalog.size).to eq(2)
      expect(catalog).to include(
        { id: dish_1.id, name: 'Carne molida con papas', category: 'Lunch' },
        { id: dish_2.id, name: 'Shawarma de bisteck', category: 'Dinner' }
      )
    end
  end

  describe '#import_plan' do
    let(:import_data) do
      {
        status: 'success',
        meal_plan: [
          { day: 'Monday', lunch_dish_id: dish_1.id, dinner_dish_id: dish_2.id },
          { day: 'Tuesday', lunch_dish_id: nil, dinner_dish_id: dish_1.id }
        ]
      }
    end

    it 'creates or updates meal plans from JSON payload' do
      importer = AiCopilotService.new
      success = importer.import_plan(import_data)

      expect(success).to be_truthy

      monday_plan = MealPlan.find_by(day_of_week: 'Monday')
      expect(monday_plan).to be_present
      expect(monday_plan.lunch_dish).to eq(dish_1)
      expect(monday_plan.dinner_dish).to eq(dish_2)

      tuesday_plan = MealPlan.find_by(day_of_week: 'Tuesday')
      expect(tuesday_plan).to be_present
      expect(tuesday_plan.lunch_dish).to be_nil
      expect(tuesday_plan.dinner_dish).to eq(dish_1)
    end

    it 'returns false if validation or processing fails' do
      invalid_data = {
        status: 'success',
        meal_plan: [
          { day: 'InvalidDay', lunch_dish_id: dish_1.id, dinner_dish_id: nil }
        ]
      }
      importer = AiCopilotService.new
      expect(importer.import_plan(invalid_data)).to be_falsey
    end
  end
end
