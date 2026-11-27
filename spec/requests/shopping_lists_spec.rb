require "rails_helper"

RSpec.describe "ShoppingLists", type: :request do
  let!(:chicken) { Ingredient.create!(name: "Pechuga de pollo", supermarket_section: "Carnicería", pantry_staple: false) }
  let!(:potato) { Ingredient.create!(name: "Papa", supermarket_section: "Verdulería", pantry_staple: false) }
  let!(:olive_oil) { Ingredient.create!(name: "Aceite de oliva", supermarket_section: "Despensa", pantry_staple: true) }

  let!(:dish) do
    record = Dish.create!(name: "Pollo con papas", categories: [ "Lunch", "Dinner" ])
    DishIngredient.create!(dish: record, ingredient: chicken, suggested_quantity: "90g")
    DishIngredient.create!(dish: record, ingredient: potato, suggested_quantity: "360g")
    DishIngredient.create!(dish: record, ingredient: olive_oil, suggested_quantity: "15ml")
    record
  end

  describe "GET /shopping_list (public guest access)", unauthenticated: true do
    before do
      MealPlan.create!(day_of_week: "Monday", lunch_dish: dish)
      MealPlan.create!(day_of_week: "Tuesday", lunch_dish: dish)
    end

    it "renders the interactive shopping list without login using default 2 servings" do
      get shopping_list_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("shopping_lists.show.title"))
      expect(response.body).to include("Pechuga de pollo")
      # 90g * 2 days * 2 servings = 360g
      expect(response.body).to include("360g")
      # 360g * 2 days * 2 servings = 1440g => 1.44 kg
      expect(response.body).to include("1.44 kg")
      # Pantry staple separated into pantry tab
      expect(response.body).to include("Aceite de oliva")
      expect(response.body).to include("60ml")
      expect(response.body).to include(I18n.t("shopping_lists.show.copy_whatsapp"))
    end

    it "scales quantities via ?servings=3 and persists the cookie for subsequent requests" do
      get shopping_list_path(servings: 3)

      expect(response).to have_http_status(:ok)
      # 90g * 2 days * 3 servings = 540g
      expect(response.body).to include("540g")
      expect(cookies["shopping_servings"]).to eq("3")

      get shopping_list_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("540g")
    end

    it "falls back safely when servings param is out of bounds" do
      get shopping_list_path(servings: 99)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("360g")
    end
  end

  describe "GET /shopping_list when an ingredient is used in 3 or more dishes", unauthenticated: true do
    let!(:dish_2) do
      record = Dish.create!(name: "Pollo con arroz y brócoli", categories: [ "Lunch" ])
      DishIngredient.create!(dish: record, ingredient: chicken, suggested_quantity: "90g")
      record
    end
    let!(:dish_3) do
      record = Dish.create!(name: "Pollo con yuca y ensalada", categories: [ "Dinner" ])
      DishIngredient.create!(dish: record, ingredient: chicken, suggested_quantity: "90g")
      record
    end

    before do
      MealPlan.create!(day_of_week: "Monday", lunch_dish: dish, dinner_dish: dish_2)
      MealPlan.create!(day_of_week: "Tuesday", lunch_dish: dish_3)
    end

    it "renders a compact collapsible meal count toggle instead of a wall of dish names" do
      get shopping_list_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("shopping-usage-toggle")
      expect(response.body).to include(I18n.t("shopping_lists.show.used_in_meals", count: 3))
    end
  end

  describe "GET /shopping_list when no meals are planned", unauthenticated: true do
    it "displays the empty state message" do
      get shopping_list_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("shopping_lists.show.empty_title"))
    end
  end
end
