require "rails_helper"

RSpec.describe "db/seeds.rb" do
  it "seeds only Lunch & Dinner diet dishes with pantry_staple flags and no Breakfast or Snack dishes" do
    expect { load Rails.root.join("db/seeds.rb") }.not_to raise_error

    expect(Dish.count).to eq(16)
    expect(Dish.all.flat_map(&:effective_categories).uniq).to contain_exactly("Lunch", "Dinner")
    expect(Ingredient.find_by!(name: "Aceite de oliva").pantry_staple?).to be(true)
    expect(Ingredient.find_by!(name: "Arroz integral").pantry_staple?).to be(true)
    expect(Ingredient.find_by!(name: "Pechuga de pollo").pantry_staple?).to be(false)

    # Idempotent on second run
    expect { load Rails.root.join("db/seeds.rb") }.not_to change(Dish, :count)
  end
end
