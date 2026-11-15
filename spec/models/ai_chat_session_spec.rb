require 'rails_helper'

RSpec.describe AiChatSession, type: :model do
  describe "associations" do
    it "has many ai_chat_messages with dependent destroy" do
      association = described_class.reflect_on_association(:ai_chat_messages)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "is valid with a title and valid status" do
      session = described_class.new(title: "Plan Semanal - Nov", status: "active")
      expect(session).to be_valid
    end

    it "is invalid without a title" do
      session = described_class.new(title: "", status: "active")
      expect(session).not_to be_valid
    end

    it "is invalid with an unknown status" do
      session = described_class.new(title: "Plan Semanal", status: "archived")
      expect(session).not_to be_valid
    end
  end

  describe "status predicates" do
    it "returns true for active? when status is active" do
      session = described_class.new(title: "Plan", status: "active")
      expect(session.active?).to be true
      expect(session.applied?).to be false
    end

    it "returns true for applied? when status is applied" do
      session = described_class.new(title: "Plan", status: "applied")
      expect(session.applied?).to be true
      expect(session.active?).to be false
    end
  end
end
