require 'rails_helper'

RSpec.describe "AiChatSessions & Gemini Pseudo-Chat", type: :request do
  let!(:dish1) { Dish.create!(name: "Milanesa de pollo", category: "Lunch") }
  let!(:dish2) { Dish.create!(name: "Ensalada César", category: "Dinner") }

  describe "POST /ai_chat_sessions" do
    it "creates a new chat session and redirects to root" do
      expect {
        post ai_chat_sessions_path
      }.to change(AiChatSession, :count).by(1)

      expect(response).to redirect_to(root_path(anchor: "ai-copilot-panel"))
    end
  end

  describe "POST /ai_chat_sessions/:ai_chat_session_id/ai_chat_messages" do
    let!(:chat_session) { AiChatSession.create!(title: "Sesión Activa") }

    it "sends the user message and parameters to Gemini, stores the reply and proposed menu, and redirects" do
      fake_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(fake_client)
      allow(fake_client).to receive(:generate_plan_response).and_return({
        reply: "He preparado el menú con Milanesa de pollo y Ensalada César.",
        meal_plan: [
          { "day" => "Monday", "lunch_dish_id" => dish1.id, "dinner_dish_id" => dish2.id }
        ]
      })

      expect {
        post ai_chat_session_ai_chat_messages_path(chat_session), params: {
          ai_chat_message: {
            content: "Planifica el lunes con pollo y ensalada",
            days_scope: "weekdays",
            include_lunch: "1",
            include_dinner: "1",
            avoid_repetition: "1"
          }
        }
      }.to change(AiChatMessage, :count).by(2)

      expect(response).to redirect_to(root_path(anchor: "ai-copilot-panel"))
      follow_redirect!
      expect(response.body).to include("He preparado el menú con Milanesa de pollo y Ensalada César.")
      expect(response.body).to include("Milanesa de pollo")
    end
  end

  describe "POST /ai_chat_sessions/:id/apply" do
    let!(:chat_session) do
      AiChatSession.create!(
        title: "Sesión con Propuesta",
        proposed_plan: [
          { "day" => "Monday", "lunch_dish_id" => dish1.id, "dinner_dish_id" => dish2.id }
        ]
      )
    end

    it "loads the proposed plan into the weekly calendar and updates status to applied" do
      post apply_ai_chat_session_path(chat_session)
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq(I18n.t("ai_chat_sessions.controller.applied"))

      plan = MealPlan.find_by(day_of_week: "Monday")
      expect(plan.lunch_dish).to eq(dish1)
      expect(plan.dinner_dish).to eq(dish2)
      expect(chat_session.reload.applied?).to be true
    end
  end

  describe "DELETE /ai_chat_sessions/:id" do
    let!(:chat_session) { AiChatSession.create!(title: "Sesión Temporal") }

    it "deletes the chat session and redirects to root" do
      expect {
        delete ai_chat_session_path(chat_session)
      }.to change(AiChatSession, :count).by(-1)

      expect(response).to redirect_to(root_path(anchor: "ai-copilot-panel"))
    end
  end
end
