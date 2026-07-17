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
  end
end
