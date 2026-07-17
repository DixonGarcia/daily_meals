require 'rails_helper'

RSpec.describe "MealPlans", type: :request do
  let!(:dish) { Dish.create!(name: 'Carne molida con papas', category: 'Lunch') }

  describe "GET /" do
    it "renders the dashboard / weekly calendar" do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Monday')
      expect(response.body).to include('Tuesday')
    end
  end

  describe "PATCH /meal_plans" do
    it "updates the meal plan for a specific day" do
      patch update_day_meal_plans_path, params: { day_of_week: 'Monday', lunch_dish_id: dish.id, dinner_dish_id: nil }
      expect(response).to redirect_to(root_path)

      plan = MealPlan.find_by(day_of_week: 'Monday')
      expect(plan.lunch_dish).to eq(dish)
      expect(plan.dinner_dish).to be_nil
    end
  end
end
