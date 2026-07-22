require 'rails_helper'

RSpec.describe "Api::V1::MealPlans", type: :request do
  let!(:api_key) { ApiKey.create!(name: "Test Client") }
  let(:token) { api_key.token }

  let!(:dish_lunch) { Dish.create!(name: "Chilaquiles", category: "Breakfast") }
  let!(:dish_dinner) { Dish.create!(name: "Quesadillas", category: "Dinner") }

  describe "GET /api/v1/meal_plans" do
    context "without authorization" do
      it "returns unauthorized status" do
        get api_v1_meal_plans_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid token" do
      before do
        MealPlan.create!(day_of_week: "Monday", lunch_dish: dish_lunch, dinner_dish: dish_dinner)
      end

      it "returns the active meal plans" do
        get api_v1_meal_plans_path, headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        monday_plan = json.find { |p| p['day_of_week'] == 'Monday' }
        expect(monday_plan['lunch_dish_id']).to eq(dish_lunch.id)
        expect(monday_plan['dinner_dish_id']).to eq(dish_dinner.id)
      end
    end
  end

  describe "POST /api/v1/meal_plans/import" do
    let(:import_payload) do
      {
        meal_plan: [
          { day: "Monday", lunch_dish_id: dish_lunch.id, dinner_dish_id: dish_dinner.id },
          { day: "Tuesday", lunch_dish_id: nil, dinner_dish_id: dish_dinner.id }
        ]
      }
    end

    context "with valid parameters" do
      it "updates the weekly meal plans" do
        post import_api_v1_meal_plans_path,
             params: import_payload.to_json,
             headers: { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)

        monday_plan = MealPlan.find_by(day_of_week: "Monday")
        expect(monday_plan.lunch_dish_id).to eq(dish_lunch.id)
        expect(monday_plan.dinner_dish_id).to eq(dish_dinner.id)

        tuesday_plan = MealPlan.find_by(day_of_week: "Tuesday")
        expect(tuesday_plan.lunch_dish_id).to be_nil
        expect(tuesday_plan.dinner_dish_id).to eq(dish_dinner.id)
      end
    end

    context "with invalid day_of_week in payload" do
      it "rolls back updates on validation error" do
        bad_payload = {
          meal_plan: [
            { day: "InvalidDay", lunch_dish_id: dish_lunch.id, dinner_dish_id: nil }
          ]
        }

        expect {
          post import_api_v1_meal_plans_path,
               params: bad_payload.to_json,
               headers: { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
        }.not_to change(MealPlan, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
