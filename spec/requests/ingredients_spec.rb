require "rails_helper"

RSpec.describe "Ingredients", type: :request do
  describe "POST /ingredients" do
    it "creates an ingredient with Charcutería section and pantry_staple flag" do
      expect {
        post ingredients_path, params: {
          ingredient: {
            name: "Queso paisa",
            supermarket_section: "Charcutería",
            pantry_staple: true
          }
        }
      }.to change(Ingredient, :count).by(1)

      expect(response).to redirect_to(ingredients_path)
      created = Ingredient.find_by!(name: "Queso paisa")
      expect(created.supermarket_section).to eq("Charcutería")
      expect(created.pantry_staple?).to be(true)
    end
  end

  describe "PATCH /ingredients/:id" do
    let!(:rice) { Ingredient.create!(name: "Arroz blanco", supermarket_section: "Víveres", pantry_staple: false) }

    it "updates pantry_staple and displays the pantry badge on index" do
      patch ingredient_path(rice), params: {
        ingredient: {
          name: "Arroz blanco",
          supermarket_section: "Víveres",
          pantry_staple: true
        }
      }

      expect(response).to redirect_to(ingredients_path)
      expect(rice.reload.pantry_staple?).to be(true)

      get ingredients_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("ingredients.index.pantry_badge"))
    end
  end
end
