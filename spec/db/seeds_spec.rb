require "rails_helper"

RSpec.describe "db/seeds.rb" do
  it "seeds 16 concise Lunch & Dinner dishes with real vegetables and pantry_staple flags" do
    expect { load Rails.root.join("db/seeds.rb") }.not_to raise_error

    expect(Dish.count).to eq(16)
    expect(Dish.all.flat_map(&:effective_categories).uniq).to contain_exactly("Lunch", "Dinner")
    expect(Dish.pluck(:name)).to all(satisfy { |n| !n.downcase.include?("post-entreno") })
    expect(Ingredient.find_by(name: "Vegetales mixtos")).to be_nil
    expect(Ingredient.find_by!(name: "Brócoli").pantry_staple?).to be(false)
    expect(Ingredient.find_by!(name: "Aceite de oliva").pantry_staple?).to be(true)
    expect(Ingredient.find_by!(name: "Arroz integral").pantry_staple?).to be(true)
    expect(Ingredient.find_by!(name: "Pechuga de pollo").pantry_staple?).to be(false)

    # Idempotent on second run
    expect { load Rails.root.join("db/seeds.rb") }.not_to change(Dish, :count)
  end
end
