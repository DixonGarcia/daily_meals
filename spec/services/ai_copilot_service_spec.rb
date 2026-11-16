require 'rails_helper'

RSpec.describe AiCopilotService do
  let!(:dish1) { Dish.create!(name: 'Carne molida con papas', category: 'Lunch') }
  let!(:dish2) { Dish.create!(name: 'Pasta boloñesa', category: 'Dinner') }
  let(:service) { described_class.new }

  describe '#export_catalog' do
    it 'exports all dishes and includes user restrictions' do
      result = service.export_catalog('Plan Monday to Friday. No chicken.')

      expect(result[:restrictions]).to eq('Plan Monday to Friday. No chicken.')
      expect(result[:dish_catalog]).to be_an(Array)
      expect(result[:dish_catalog].size).to eq(2)
      expect(result[:dish_catalog]).to include(
        { id: dish1.id, name: 'Carne molida con papas', category: 'Lunch' },
        { id: dish2.id, name: 'Pasta boloñesa', category: 'Dinner' }
      )
    end
  end

  describe '#import_plan' do
    it 'imports a valid JSON payload and updates MealPlan records' do
      payload = {
        status: 'success',
        meal_plan: [
          { day: 'Monday', lunch_dish_id: dish1.id, dinner_dish_id: dish2.id },
          { day: 'Tuesday', lunch_dish_id: dish2.id, dinner_dish_id: nil }
        ]
      }.to_json

      expect(service.import_plan(payload)).to be true

      monday_plan = MealPlan.find_by(day_of_week: 'Monday')
      expect(monday_plan.lunch_dish).to eq(dish1)
      expect(monday_plan.dinner_dish).to eq(dish2)

      tuesday_plan = MealPlan.find_by(day_of_week: 'Tuesday')
      expect(tuesday_plan.lunch_dish).to eq(dish2)
      expect(tuesday_plan.dinner_dish).to be_nil
    end

    it 'returns false and rolls back if payload is invalid JSON' do
      expect(service.import_plan('invalid json')).to be false
      expect(MealPlan.count).to eq(0)
    end
  end

  describe '#converse!' do
    let(:chat_session) { AiChatSession.create!(title: 'Planificación Semanal') }
    let(:gemini_client) { instance_double(GeminiClient) }
    let(:service_with_client) { described_class.new(gemini_client: gemini_client) }

    it 'persists user and assistant messages, sanitizes dish IDs, and updates session proposed_plan' do
      allow(gemini_client).to receive(:generate_plan_response).and_return({
        reply: 'Propuesta lista de lunes a martes.',
        meal_plan: [
          { 'day' => 'Monday', 'lunch_dish_id' => dish1.id, 'dinner_dish_id' => 999_999 },
          { 'day' => 'Tuesday', 'lunch_dish_id' => dish2.id, 'dinner_dish_id' => dish1.id }
        ]
      })

      params_hash = { 'days_scope' => 'weekdays', 'include_lunch' => true, 'include_dinner' => true, 'avoid_repetition' => true }
      assistant_msg = service_with_client.converse!(
        session: chat_session,
        user_message: 'Armame lunes y martes sin repetir.',
        parameters: params_hash
      )

      expect(chat_session.ai_chat_messages.count).to eq(2)
      expect(assistant_msg.role).to eq('assistant')
      expect(assistant_msg.content).to eq('Propuesta lista de lunes a martes.')

      chat_session.reload
      expect(chat_session.parameters['days_scope']).to eq('weekdays')
      expect(chat_session.proposed_plan).to eq([
        { 'day' => 'Monday', 'lunch_dish_id' => dish1.id, 'dinner_dish_id' => nil },
        { 'day' => 'Tuesday', 'lunch_dish_id' => dish2.id, 'dinner_dish_id' => dish1.id }
      ])
    end

    it 'does not persist an orphaned user message when GeminiClient raises ApiError' do
      allow(gemini_client).to receive(:generate_plan_response).and_raise(GeminiClient::ApiError.new('HTTP 500'))

      expect {
        service_with_client.converse!(
          session: chat_session,
          user_message: 'Mensaje fallido',
          parameters: {}
        )
      }.to raise_error(GeminiClient::ApiError)

      expect(chat_session.ai_chat_messages.count).to eq(0)
    end
  end

  describe '#apply_session_plan!' do
    it 'applies the session proposed_plan to MealPlan and marks the session as applied' do
      chat_session = AiChatSession.create!(
        title: 'Plan Semanal',
        proposed_plan: [
          { 'day' => 'Wednesday', 'lunch_dish_id' => dish1.id, 'dinner_dish_id' => dish2.id }
        ]
      )

      expect(service.apply_session_plan!(chat_session)).to be true
      expect(chat_session.reload.applied?).to be true

      wednesday = MealPlan.find_by(day_of_week: 'Wednesday')
      expect(wednesday.lunch_dish).to eq(dish1)
      expect(wednesday.dinner_dish).to eq(dish2)
    end
  end
end
