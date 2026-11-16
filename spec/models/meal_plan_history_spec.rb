require 'rails_helper'

RSpec.describe MealPlanHistory, type: :model do
  let!(:lunch_dish) { Dish.create!(name: 'Pollo a la Plancha', categories: [ 'Lunch' ]) }
  let!(:dinner_dish) { Dish.create!(name: 'Crema de Calabacín', categories: [ 'Dinner' ]) }

  describe 'validations' do
    it 'validates uniqueness of week_number scoped to year and range 1..53' do
      described_class.create!(
        year: 2026,
        week_number: 47,
        week_start_date: Date.new(2026, 11, 16),
        week_end_date: Date.new(2026, 11, 22),
        source: 'manual',
        plan_snapshot: []
      )

      duplicate = described_class.new(
        year: 2026,
        week_number: 47,
        week_start_date: Date.new(2026, 11, 16),
        week_end_date: Date.new(2026, 11, 22),
        source: 'manual',
        plan_snapshot: []
      )
      expect(duplicate).not_to be_valid

      out_of_range = described_class.new(
        year: 2026,
        week_number: 54,
        week_start_date: Date.new(2026, 12, 28),
        week_end_date: Date.new(2027, 1, 3),
        source: 'manual',
        plan_snapshot: []
      )
      expect(out_of_range).not_to be_valid
    end
  end

  describe '.record_current_week!' do
    before do
      MealPlan::DAYS_OF_WEEK.each { |d| MealPlan.find_or_create_by!(day_of_week: d) }
      MealPlan.find_by!(day_of_week: 'Monday').update!(lunch_dish: lunch_dish, dinner_dish: dinner_dish)
    end

    it 'creates an ISO-week snapshot of Monday..Sunday MealPlan records and updates idempotently' do
      target = Date.new(2026, 11, 18) # Wednesday of ISO week 47, 2026
      history = described_class.record_current_week!(target_date: target, source: 'ai_copilot')

      expect(history.year).to eq(2026)
      expect(history.week_number).to eq(47)
      expect(history.week_start_date).to eq(Date.new(2026, 11, 16))
      expect(history.week_end_date).to eq(Date.new(2026, 11, 22))
      expect(history.source).to eq('ai_copilot')

      monday_entry = history.plan_snapshot.find { |e| e['day'] == 'Monday' }
      expect(monday_entry['lunch_dish_id']).to eq(lunch_dish.id)
      expect(monday_entry['lunch_dish_name']).to eq('Pollo a la Plancha')
      expect(monday_entry['dinner_dish_id']).to eq(dinner_dish.id)
      expect(monday_entry['dinner_dish_name']).to eq('Crema de Calabacín')

      # Idempotent update on same week
      MealPlan.find_by!(day_of_week: 'Tuesday').update!(lunch_dish: lunch_dish)
      expect {
        described_class.record_current_week!(target_date: target, source: 'manual')
      }.not_to change(described_class, :count)

      history.reload
      expect(history.source).to eq('manual')
      tuesday_entry = history.plan_snapshot.find { |e| e['day'] == 'Tuesday' }
      expect(tuesday_entry['lunch_dish_name']).to eq('Pollo a la Plancha')
    end
  end

  describe '#restore_to_calendar!' do
    before do
      MealPlan::DAYS_OF_WEEK.each { |d| MealPlan.find_or_create_by!(day_of_week: d) }
    end

    it 'restores saved dishes and skips deleted dishes without raising errors' do
      deleted_dish = Dish.create!(name: 'Plato Eliminado', categories: [ 'Dinner' ])
      snapshot = [
        {
          'day' => 'Monday',
          'lunch_dish_id' => lunch_dish.id,
          'lunch_dish_name' => lunch_dish.name,
          'dinner_dish_id' => deleted_dish.id,
          'dinner_dish_name' => deleted_dish.name
        }
      ]
      deleted_dish.destroy!

      history = described_class.create!(
        year: 2026,
        week_number: 46,
        week_start_date: Date.new(2026, 11, 9),
        week_end_date: Date.new(2026, 11, 15),
        source: 'manual',
        plan_snapshot: snapshot
      )

      result = history.restore_to_calendar!
      monday = MealPlan.find_by!(day_of_week: 'Monday')
      expect(monday.lunch_dish).to eq(lunch_dish)
      expect(monday.dinner_dish).to be_nil
      expect(result[:restored_slots]).to eq(1)
      expect(result[:skipped_names]).to include('Plato Eliminado')
    end
  end
end
