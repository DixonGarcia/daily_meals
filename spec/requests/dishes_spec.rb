require 'rails_helper'

RSpec.describe "Dishes", type: :request do
  let!(:dish) { Dish.create!(name: 'Pasta boloñesa', category: 'Lunch') }

  describe "GET /dishes" do
    it "renders the dishes index page" do
      get dishes_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Pasta boloñesa')
    end
  end

  describe "POST /dishes" do
    it "creates a new dish with valid parameters" do
      expect {
        post dishes_path, params: { dish: { name: 'Ensalada César', category: 'Dinner' } }
      }.to change(Dish, :count).by(1)

      expect(response).to redirect_to(dishes_path)
    end

    it "fails to create a dish with invalid parameters" do
      expect {
        post dishes_path, params: { dish: { name: '', category: 'Lunch' } }
      }.not_to change(Dish, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "creates a dish and automatically registers brand-new inline ingredients" do
      expect {
        post dishes_path, params: {
          dish: {
            name: 'Tacos de pescado',
            category: 'Dinner',
            dish_ingredients_attributes: {
              '0' => {
                ingredient_id: '',
                ingredient_name: 'Filete de merluza',
                supermarket_section: 'Carnicería',
                suggested_quantity: '400g'
              }
            }
          }
        }
      }.to change(Dish, :count).by(1).and change(Ingredient, :count).by(1)

      created = Dish.find_by!(name: 'Tacos de pescado')
      expect(created.ingredients.first.name).to eq('Filete de merluza')
    end
  end

  describe "POST /dishes/suggest_ingredients" do
    it "returns AI-suggested category and ingredients as JSON" do
      fake_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(fake_client)
      allow(fake_client).to receive(:suggest_dish_ingredients).and_return({
        category: "Lunch",
        ingredients: [
          { "name" => "Arroz blanco", "supermarket_section" => "Víveres", "suggested_quantity" => "300g" }
        ]
      })

      post suggest_ingredients_dishes_path, params: { dish_name: "Arroz con pollo" }
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["category"]).to eq("Lunch")
      expect(body["ingredients"].first["name"]).to eq("Arroz blanco")
    end
  end
end
