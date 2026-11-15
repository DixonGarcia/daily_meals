require 'rails_helper'

RSpec.describe AiChatMessage, type: :model do
  let(:chat_session) { AiChatSession.create!(title: "Plan Semanal") }

  describe "associations" do
    it "belongs to ai_chat_session" do
      association = described_class.reflect_on_association(:ai_chat_session)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with a valid role and content" do
      message = described_class.new(ai_chat_session: chat_session, role: "user", content: "Hola Gemini")
      expect(message).to be_valid
    end

    it "is invalid with an unsupported role" do
      message = described_class.new(ai_chat_session: chat_session, role: "system", content: "Hola")
      expect(message).not_to be_valid
    end

    it "is invalid without content" do
      message = described_class.new(ai_chat_session: chat_session, role: "assistant", content: "")
      expect(message).not_to be_valid
    end
  end
end
