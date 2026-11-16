require 'rails_helper'

RSpec.describe "Api::V1::Dishes", type: :request do
  let!(:api_key) { ApiKey.create!(name: "Test Client") }
  # Extract the generated plain token to use in the headers
  # Since the test key was created via ActiveRecord, we can get its token if it was captured,
  # or we can stub/mock the token. Let's create it through the standard model creation.
  let(:token) { api_key.token }

  describe "GET /api/v1/dishes" do
    context "without authorization header" do
      it "returns unauthorized status" do
        get api_v1_dishes_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid authorization header" do
      it "returns unauthorized status" do
        get api_v1_dishes_path, headers: { "Authorization" => "Bearer invalid_token" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid authorization header" do
      let!(:dish) { Dish.create!(name: "Tacos de carnitas", category: "Lunch") }

      it "returns the list of dishes in JSON format" do
        get api_v1_dishes_path, headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.first['name']).to eq("Tacos de carnitas")
      end
    end
  end

  describe "POST /api/v1/dishes/import" do
    let(:import_payload) do
      {
        dishes: [
          {
            name: "Enchiladas Verdes",
            category: "Lunch",
            ingredients: [
              { name: "Tortilla de maíz", supermarket_section: "Despensa", suggested_quantity: "12 unidades" },
              { name: "Pechuga de pollo", supermarket_section: "Carnicería", suggested_quantity: "500g" }
            ]
          }
        ]
      }
    end

    context "with valid payload" do
      it "imports dishes and their ingredients in a transaction" do
        expect {
          post import_api_v1_dishes_path,
               params: import_payload.to_json,
               headers: { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
        }.to change(Dish, :count).by(1).and change(Ingredient, :count).by(2)

        expect(response).to have_http_status(:ok)

        dish = Dish.find_by(name: "Enchiladas Verdes")
        expect(dish.category).to eq("Lunch")
        expect(dish.ingredients.pluck(:name)).to contain_exactly("Tortilla de maíz", "Pechuga de pollo")
      end
    end

    context "with invalid payload" do
      it "does not import anything and rolls back on failure" do
        bad_payload = {
          dishes: [
            {
              name: "", # invalid name
              category: "Lunch",
              ingredients: []
            }
          ]
        }

        expect {
          post import_api_v1_dishes_path,
               params: bad_payload.to_json,
               headers: { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
        }.not_to change(Dish, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
