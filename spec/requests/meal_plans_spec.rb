require 'rails_helper'

RSpec.describe "MealPlans", type: :request do
  let!(:dish) { Dish.create!(name: 'Carne molida con papas', category: 'Lunch') }

  describe "GET /" do
    it "renders the dashboard in day view by default and supports week view via ?view=week" do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("meal_plans.index.view_day"))
      expect(response.body).to include(I18n.t("meal_plans.index.view_week"))

      get root_path(view: "week")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Lunes")
      expect(response.body).to include("Martes")
    end
  end

  describe "PATCH /meal_plans" do
    it "updates the meal plan for a specific day" do
      patch update_day_meal_plans_path, params: { day_of_week: 'Monday', lunch_dish_id: dish.id, dinner_dish_id: nil }
      expect(response).to redirect_to(root_path)

      plan = MealPlan.find_by(day_of_week: 'Monday')
      expect(plan.lunch_dish).to eq(dish)
      expect(plan.dinner_dish).to be_nil
      expect(MealPlanHistory.count).to eq(1)
    end
  end

  describe "PATCH /meal_plans/update_week" do
    let!(:dinner_dish) { Dish.create!(name: 'Pescado con arroz y aguacate', category: 'Dinner') }

    it "saves all modified days of the week atomically without losing other days" do
      patch update_week_meal_plans_path, params: {
        days: {
          Monday: { lunch_dish_id: dish.id, dinner_dish_id: dinner_dish.id },
          Tuesday: { lunch_dish_id: dish.id, dinner_dish_id: "" },
          Wednesday: { lunch_dish_id: "", dinner_dish_id: dinner_dish.id }
        }
      }

      expect(response).to redirect_to(root_path(view: "week"))
      expect(MealPlan.find_by!(day_of_week: "Monday").lunch_dish).to eq(dish)
      expect(MealPlan.find_by!(day_of_week: "Monday").dinner_dish).to eq(dinner_dish)
      expect(MealPlan.find_by!(day_of_week: "Tuesday").lunch_dish).to eq(dish)
      expect(MealPlan.find_by!(day_of_week: "Tuesday").dinner_dish).to be_nil
      expect(MealPlan.find_by!(day_of_week: "Wednesday").dinner_dish).to eq(dinner_dish)
      expect(MealPlanHistory.count).to eq(1)
    end
  end
end
