require "rails_helper"

RSpec.describe "FEAT-10 Household Diet Profile, Couple Daily UX, Cleanup & PWA", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:chicken) { Ingredient.create!(name: "Pechuga de pollo", supermarket_section: "Carnicería") }
  let!(:broccoli) { Ingredient.create!(name: "Brócoli", supermarket_section: "Verdulería") }
  let!(:fish) { Ingredient.create!(name: "Pescado", supermarket_section: "Carnicería") }

  let!(:today_dish) do
    dish = Dish.create!(name: "Pollo con arroz integral y brócoli", categories: [ "Lunch", "Dinner" ])
    DishIngredient.create!(dish: dish, ingredient: chicken, suggested_quantity: "90g")
    DishIngredient.create!(dish: dish, ingredient: broccoli, suggested_quantity: "200g")
    dish
  end

  let!(:tomorrow_dish) do
    dish = Dish.create!(name: "Pescado con arroz blanco y aguacate", categories: [ "Lunch", "Dinner" ])
    DishIngredient.create!(dish: dish, ingredient: fish, suggested_quantity: "120g")
    dish
  end

  describe "Household Diet Profile in Settings" do
    it "renders the Diet tab and persists servings_multiplier and diet_guidelines" do
      get settings_path(tab: "diet")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("settings.diet.title"))

      patch update_household_settings_path, params: {
        household_setting: {
          servings_multiplier: 3,
          diet_guidelines: "Pareja con bebé en Venezuela. Meal prep en 2 tandas."
        }
      }

      expect(response).to redirect_to(settings_path(tab: "diet"))
      setting = HouseholdSetting.current
      expect(setting.servings_multiplier).to eq(3)
      expect(setting.diet_guidelines).to include("Meal prep en 2 tandas")
    end

    it "uses HouseholdSetting.current.servings_multiplier as default on /shopping_list" do
      HouseholdSetting.current.update!(servings_multiplier: 4)
      MealPlan.create!(day_of_week: "Monday", lunch_dish: today_dish)

      get shopping_list_path
      expect(response).to have_http_status(:ok)
      # 90g * 4 servings = 360g
      expect(response.body).to include("360g")
    end

    it "blocks unauthenticated guests from updating household settings", unauthenticated: true do
      patch update_household_settings_path, params: {
        household_setting: { servings_multiplier: 5, diet_guidelines: "Hack" }
      }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "Read-first Day View, Tomorrow Defrost Radar & Dashboard Cleanup" do
    before do
      MealPlan.create!(day_of_week: "Wednesday", lunch_dish: today_dish)
      MealPlan.create!(day_of_week: "Thursday", lunch_dish: tomorrow_dish)
    end

    it "shows read-first card with edit toggle, tomorrow defrost strip, and omits legacy JSON & session switcher" do
      # 2026-11-18 16:00 UTC is Wednesday 12:00 Caracas
      travel_to Time.utc(2026, 11, 18, 16, 0, 0) do
        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("meal_plans.index.edit_day"))
        expect(response.body).to include("tomorrow-radar-strip")
        expect(response.body).to include("Jueves")
        expect(response.body).to include("Pescado con arroz blanco y aguacate")
        expect(response.body).to include("Pescado")
        expect(response.body).to include(I18n.t("meal_plans.index.defrost_alert", items: "Pescado"))

        expect(response.body).not_to include("legacy-json-details")
        expect(response.body).not_to include("session-switcher-box")
      end
    end
  end

  describe "Smart Back Navigation on /dishes/:id" do
    it "links back to calendar when navigated from calendar" do
      get dish_path(today_dish, from: "calendar")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("dishes.show.back_to_calendar"))
      expect(response.body).to include("href=\"#{root_path}\"")
    end
  end

  describe "Biteclub PWA manifest & active Service Worker", unauthenticated: true do
    it "serves Biteclub theme colors in manifest.json and active cache logic in service-worker" do
      get pwa_manifest_path(format: :json)
      expect(response).to have_http_status(:ok)
      manifest = JSON.parse(response.body)
      expect(manifest["theme_color"]).to eq("#ffffff")
      expect(manifest["background_color"]).to eq("#f8f9fa")
      expect(manifest["short_name"]).to eq("DailyMeals")

      get pwa_service_worker_path(format: :js)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dailymeals-v1")
      expect(response.body).to include("addEventListener(\"fetch\"")
    end
  end
end
