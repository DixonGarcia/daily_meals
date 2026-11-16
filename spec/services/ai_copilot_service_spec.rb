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
        { id: dish1.id, name: 'Carne molida con papas', category: 'Lunch', categories: [ 'Lunch' ] },
        { id: dish2.id, name: 'Pasta boloñesa', category: 'Dinner', categories: [ 'Dinner' ] }
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

    it 'sanitizes and persists proposed new_dishes alongside meal_plan' do
      allow(gemini_client).to receive(:generate_plan_response).and_return({
        reply: 'Te propongo Pollo al curry para el miércoles.',
        new_dishes: [
          {
            'name' => 'Pollo al curry',
            'category' => 'Lunch',
            'ingredients' => [
              { 'name' => 'Pechuga de pollo', 'supermarket_section' => 'Carnicería', 'suggested_quantity' => '500g' },
              { 'name' => 'Leche de coco', 'supermarket_section' => 'Sección inventada', 'suggested_quantity' => '1 lata' }
            ]
          }
        ],
        meal_plan: [
          { 'day' => 'Wednesday', 'lunch_dish_id' => nil, 'lunch_new_dish_name' => 'Pollo al curry', 'dinner_dish_id' => dish2.id }
        ]
      })

      service_with_client.converse!(
        session: chat_session,
        user_message: 'Pon Pollo al curry el miércoles',
        parameters: {}
      )

      chat_session.reload
      expect(chat_session.proposed_dishes.size).to eq(1)
      expect(chat_session.proposed_dishes.first['name']).to eq('Pollo al curry')
      expect(chat_session.proposed_dishes.first['ingredients'].last['supermarket_section']).to eq('Otros')
      expect(chat_session.proposed_plan.first['lunch_new_dish_name']).to eq('Pollo al curry')
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

    it 'creates new dishes and checked ingredients with overridden quantities and links them to MealPlan' do
      existing_ing = Ingredient.create!(name: 'Pechuga de pollo', supermarket_section: 'Carnicería')

      chat_session = AiChatSession.create!(
        title: 'Plan con Platos Nuevos',
        proposed_dishes: [
          {
            'name' => 'Pollo al curry',
            'category' => 'Lunch',
            'ingredients' => [
              { 'name' => 'pechuga de pollo', 'supermarket_section' => 'Carnicería', 'suggested_quantity' => '500g' },
              { 'name' => 'Leche de coco', 'supermarket_section' => 'Víveres', 'suggested_quantity' => '1 lata' },
              { 'name' => 'Cilantro', 'supermarket_section' => 'Verdulería', 'suggested_quantity' => '1 manojo' }
            ]
          }
        ],
        proposed_plan: [
          { 'day' => 'Thursday', 'lunch_dish_id' => nil, 'lunch_new_dish_name' => 'Pollo al curry', 'dinner_dish_id' => dish2.id }
        ]
      )

      overrides = {
        '0' => {
          'included' => '1',
          'name' => 'Pollo al curry',
          'category' => 'Lunch',
          'ingredients' => {
            '0' => { 'included' => '1', 'name' => 'pechuga de pollo', 'supermarket_section' => 'Carnicería', 'suggested_quantity' => '750g' },
            '1' => { 'included' => '1', 'name' => 'Leche de coco', 'supermarket_section' => 'Víveres', 'suggested_quantity' => '2 latas' },
            '2' => { 'included' => '0', 'name' => 'Cilantro', 'supermarket_section' => 'Verdulería', 'suggested_quantity' => '1 manojo' }
          }
        }
      }

      expect {
        expect(service.apply_session_plan!(chat_session, dish_overrides: overrides)).to be true
      }.to change(Dish, :count).by(1).and change(Ingredient, :count).by(1)

      new_dish = Dish.find_by!(name: 'Pollo al curry')
      expect(new_dish.ingredients).to contain_exactly(existing_ing, Ingredient.find_by!(name: 'Leche de coco'))
      expect(new_dish.dish_ingredients.find_by(ingredient: existing_ing).suggested_quantity).to eq('750g')
      expect(Ingredient.find_by(name: 'Cilantro')).to be_nil

      thursday = MealPlan.find_by(day_of_week: 'Thursday')
      expect(thursday.lunch_dish).to eq(new_dish)
      expect(thursday.dinner_dish).to eq(dish2)
    end
  end

  describe '#suggest_ingredients_for_dish' do
    let(:gemini_client) { instance_double(GeminiClient) }
    let(:service_with_client) { described_class.new(gemini_client: gemini_client) }

    it 'returns normalized category and ingredients with existing ingredient IDs matched' do
      existing = Ingredient.create!(name: 'Carne molida', supermarket_section: 'Carnicería')
      allow(gemini_client).to receive(:suggest_dish_ingredients).and_return({
        category: 'Dinner',
        ingredients: [
          { 'name' => 'carne molida', 'supermarket_section' => 'Carnicería', 'suggested_quantity' => '400g' },
          { 'name' => 'Tortillas de maíz', 'supermarket_section' => 'Panadería', 'suggested_quantity' => '1 paquete' }
        ]
      })

      result = service_with_client.suggest_ingredients_for_dish('Tacos de carne')
      expect(result[:category]).to eq('Dinner')
      expect(result[:categories]).to eq(['Dinner'])
      expect(result[:ingredients].first[:ingredient_id]).to eq(existing.id)
      expect(result[:ingredients].first[:name]).to eq('Carne molida')
      expect(result[:ingredients].last[:ingredient_id]).to be_nil
      expect(result[:ingredients].last[:name]).to eq('Tortillas de maíz')
    end
  end

  describe 'FEAT-06 slot preservation, duplicate-day merging, none scope & multi-category' do
    let(:gemini_client) { instance_double(GeminiClient) }
    let(:service_with_client) { described_class.new(gemini_client: gemini_client) }

    it 'merges duplicate day entries returned by Gemini and preserves existing lunch when updating only dinner' do
      MealPlan.create!(day_of_week: 'Monday', lunch_dish: dish1, dinner_dish: nil)
      chat_session = AiChatSession.create!(
        title: 'Solo cenas',
        parameters: { 'days_scope' => 'weekdays', 'include_lunch' => false, 'include_dinner' => true, 'avoid_repetition' => true }
      )

      allow(gemini_client).to receive(:generate_plan_response).and_return({
        reply: 'Cenas listas sin tocar almuerzos.',
        new_dishes: [
          {
            'name' => 'Hígado encebollado',
            'categories' => ['Lunch', 'Dinner'],
            'ingredients' => [
              { 'name' => 'Hígado', 'supermarket_section' => 'Carnicería', 'suggested_quantity' => '250g' }
            ]
          }
        ],
        meal_plan: [
          { 'day' => 'Monday', 'lunch_dish_id' => dish1.id, 'dinner_dish_id' => nil },
          { 'day' => 'Monday', 'lunch_dish_id' => nil, 'dinner_new_dish_name' => 'Hígado encebollado' }
        ]
      })

      service_with_client.converse!(
        session: chat_session,
        user_message: 'Crea cenas nuevas sin borrar mi almuerzo',
        parameters: { 'days_scope' => 'weekdays', 'include_lunch' => false, 'include_dinner' => true }
      )

      chat_session.reload
      expect(chat_session.proposed_plan.size).to eq(1)
      expect(chat_session.proposed_dishes.first['categories']).to eq(['Lunch', 'Dinner'])

      expect(service_with_client.apply_session_plan!(chat_session)).to be true

      monday = MealPlan.find_by!(day_of_week: 'Monday')
      expect(monday.lunch_dish).to eq(dish1)
      expect(monday.dinner_dish.name).to eq('Hígado encebollado')
      expect(monday.dinner_dish.categories).to eq(['Lunch', 'Dinner'])

      chat_session.reload
      expect(chat_session.proposed_plan).to eq([])
      expect(chat_session.proposed_dishes).to eq([])
    end

    it 'forces proposed_plan to empty when days_scope is none and creates dishes without touching MealPlan' do
      MealPlan.create!(day_of_week: 'Monday', lunch_dish: dish1, dinner_dish: dish2)
      chat_session = AiChatSession.create!(
        title: 'Solo platos',
        proposed_plan: [{ 'day' => 'Monday', 'lunch_dish_id' => dish2.id }]
      )

      allow(gemini_client).to receive(:generate_plan_response).and_return({
        reply: 'Aquí tienes el plato nuevo para tu catálogo.',
        new_dishes: [
          {
            'name' => 'Pescado al vapor',
            'categories' => ['Lunch', 'Dinner'],
            'ingredients' => [
              { 'name' => 'Pescado', 'supermarket_section' => 'Carnicería', 'suggested_quantity' => '300g' }
            ]
          }
        ],
        meal_plan: [{ 'day' => 'Monday', 'lunch_dish_id' => nil, 'dinner_dish_id' => nil }]
      })

      service_with_client.converse!(
        session: chat_session,
        user_message: 'Agrega Pescado al vapor al catálogo',
        parameters: { 'days_scope' => 'none', 'include_lunch' => false, 'include_dinner' => false }
      )

      chat_session.reload
      expect(chat_session.proposed_plan).to eq([])
      expect(chat_session.proposed_dishes.size).to eq(1)

      expect(service_with_client.apply_session_plan!(chat_session)).to be true
      expect(Dish.find_by(name: 'Pescado al vapor').categories).to eq(['Lunch', 'Dinner'])
      monday = MealPlan.find_by!(day_of_week: 'Monday')
      expect(monday.lunch_dish).to eq(dish1)
      expect(monday.dinner_dish).to eq(dish2)
      expect(MealPlanHistory.count).to eq(0)
    end

    it 'records MealPlanHistory with source ai_copilot when applying a calendar plan' do
      chat_session = AiChatSession.create!(title: 'Menu semana', parameters: AiChatSession::DEFAULT_PARAMETERS)
      chat_session.update!(
        proposed_plan: [{ 'day' => 'Monday', 'lunch_dish_id' => dish1.id, 'dinner_dish_id' => dish2.id }],
        proposed_dishes: []
      )

      expect(service_with_client.apply_session_plan!(chat_session)).to be true
      expect(MealPlanHistory.count).to eq(1)
      expect(MealPlanHistory.last.source).to eq('ai_copilot')
    end
  end
end
