require "rails_helper"

RSpec.describe HouseholdSetting, type: :model do
  describe "validations" do
    it "is valid with servings_multiplier between 1 and 10" do
      setting = described_class.new(servings_multiplier: 2, diet_guidelines: "Plan 2172 kcal Venezuela")
      expect(setting).to be_valid
    end

    it "is invalid when servings_multiplier is outside 1..10" do
      expect(described_class.new(servings_multiplier: 0)).not_to be_valid
      expect(described_class.new(servings_multiplier: 11)).not_to be_valid
      expect(described_class.new(servings_multiplier: nil)).not_to be_valid
    end
  end

  describe ".current" do
    it "creates and returns a default singleton record when none exists" do
      expect { described_class.current }.to change(described_class, :count).by(1)
      setting = described_class.current
      expect(setting.servings_multiplier).to eq(2)
      expect(setting.diet_guidelines).to eq("")
      expect(setting.guidelines_present?).to be(false)
    end

    it "reuses the existing record on subsequent calls" do
      existing = described_class.create!(servings_multiplier: 3, diet_guidelines: "Meal prep en 2 tandas")
      expect(described_class.current).to eq(existing)
      expect(existing.guidelines_present?).to be(true)
    end
  end
end
