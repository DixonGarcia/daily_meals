require "rails_helper"

RSpec.describe "Guest Read-Only Access, Day/Week Toggle & Caracas Time Zone", type: :request, unauthenticated: true do
  include ActiveSupport::Testing::TimeHelpers

  let!(:chicken) { Ingredient.create!(name: "Pechuga de pollo", supermarket_section: "Carnicería") }
  let!(:rice) { Ingredient.create!(name: "Arroz integral", supermarket_section: "Víveres") }
  let!(:lunch_dish) do
    dish = Dish.create!(name: "Pollo con arroz integral", categories: [ "Lunch", "Dinner" ])
    DishIngredient.create!(dish: dish, ingredient: chicken, suggested_quantity: "90g")
    DishIngredient.create!(dish: dish, ingredient: rice, suggested_quantity: "160g")
    dish
  end

  before do
    MealPlan::DAYS_OF_WEEK.each { |d| MealPlan.find_or_create_by!(day_of_week: d) }
    MealPlan.find_by!(day_of_week: "Wednesday").update!(lunch_dish: lunch_dish)
  end

  describe "GET / (Guest Day View & Caracas Time Zone)" do
    it "renders today's meal in Caracas time (UTC-4) without requiring login or creating an AiChatSession" do
      # 2026-11-19 02:00 UTC is already Thursday in UTC/Helsinki, but Wednesday 22:00 in Caracas (UTC-4)
      travel_to Time.utc(2026, 11, 19, 2, 0, 0) do
        expect {
          get root_path
        }.not_to change(AiChatSession, :count)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Miércoles")
        expect(response.body).to include("Pollo con arroz integral")
        expect(response.body).to include("Pechuga de pollo")
        expect(response.body).to include("90g")
        expect(response.body).to include(I18n.t("meal_plans.index.shopping_list"))
        expect(response.body).to include(I18n.t("layout.login"))

        expect(response.body).not_to include("ai-copilot-panel")
        expect(response.body).not_to include("copilot-chat-form")
        expect(response.body).not_to include("meal-dish-selector")
      end
    end

    it "allows switching to another day via ?day=Monday or full week view via ?view=week" do
      travel_to Time.utc(2026, 11, 19, 2, 0, 0) do
        get root_path(view: "week")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Lunes")
        expect(response.body).to include("Martes")
        expect(response.body).to include("Domingo")
        expect(response.body).not_to include("meal-dish-selector")
      end
    end
  end

  describe "GET /dishes and GET /dishes/:id (Guest Read-Only Catalog)" do
    it "renders the dish catalog without add/edit/delete or ingredients buttons" do
      get dishes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pollo con arroz integral")
      expect(response.body).not_to include(I18n.t("dishes.index.add_new"))
      expect(response.body).not_to include(I18n.t("dishes.index.ingredients_button"))
      expect(response.body).not_to include(I18n.t("dishes.index.table.actions"))
      expect(response.body).not_to include(I18n.t("dishes.index.actions.edit"))
      expect(response.body).not_to include(I18n.t("dishes.index.actions.delete"))
    end

    it "renders the dish show page with ingredients but without the edit button" do
      get dish_path(lunch_dish)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pollo con arroz integral")
      expect(response.body).to include("Pechuga de pollo")
      expect(response.body).to include("90g")
      expect(response.body).not_to include(I18n.t("dishes.show.edit_dish"))
    end
  end

  describe "Protected endpoints redirect guests to login" do
    it "blocks dish mutations, AI suggestions, ingredients catalog, settings, and calendar updates" do
      get new_dish_path
      expect(response).to redirect_to(new_session_path)

      get edit_dish_path(lunch_dish)
      expect(response).to redirect_to(new_session_path)

      post dishes_path, params: { dish: { name: "Hack", categories: [ "Lunch" ] } }
      expect(response).to redirect_to(new_session_path)

      patch dish_path(lunch_dish), params: { dish: { name: "Hack" } }
      expect(response).to redirect_to(new_session_path)

      delete dish_path(lunch_dish)
      expect(response).to redirect_to(new_session_path)

      post suggest_ingredients_dishes_path, params: { dish_name: "Pollo" }
      expect(response).to redirect_to(new_session_path)

      get ingredients_path
      expect(response).to redirect_to(new_session_path)

      get settings_path
      expect(response).to redirect_to(new_session_path)

      patch update_day_meal_plans_path, params: { day_of_week: "Wednesday", lunch_dish_id: nil }
      expect(response).to redirect_to(new_session_path)
    end
  end
end
