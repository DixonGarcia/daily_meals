require 'rails_helper'

RSpec.describe "AiCopilots", type: :request do
  let!(:dish) { Dish.create!(name: 'Pasta boloñesa', category: 'Lunch') }

  describe "GET /ai_copilot/export" do
    it "exports the catalog with restrictions" do
      get export_ai_copilot_path, params: { restrictions: 'Avoid meat' }
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json['dish_catalog']).to be_present
      expect(json['restrictions']).to eq('Avoid meat')
    end
  end

  describe "POST /ai_copilot/import" do
    it "imports the plan and redirects to root" do
      payload = {
        status: 'success',
        meal_plan: [
          { day: 'Monday', lunch_dish_id: dish.id, dinner_dish_id: nil }
        ]
      }.to_json

      post import_ai_copilot_path, params: { payload: payload }
      expect(response).to redirect_to(root_path)

      plan = MealPlan.find_by(day_of_week: 'Monday')
      expect(plan.lunch_dish).to eq(dish)
    end

    it "shows alert when import fails" do
      post import_ai_copilot_path, params: { payload: 'invalid json' }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t('ai_copilots.controller.error_import'))
    end
  end
end
