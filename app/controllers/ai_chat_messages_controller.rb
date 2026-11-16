# Handles sending user messages and planning parameters to Gemini within an AiChatSession.
class AiChatMessagesController < ApplicationController
  rate_limit to: 15, within: 5.minutes, only: :create, with: -> {
    redirect_to root_path(anchor: "ai-copilot-panel"), alert: t("ai_chat_messages.controller.rate_limited")
  }

  # POST /ai_chat_sessions/:ai_chat_session_id/ai_chat_messages
  # Persists the user prompt, updates session parameters, queries Gemini, and stores the assistant response.
  #
  # @return [void]
  def create
    chat_session = AiChatSession.find(params.expect(:ai_chat_session_id))
    session[:active_ai_chat_session_id] = chat_session.id

    msg_params = params.expect(
      ai_chat_message: %i[content days_scope include_lunch include_dinner avoid_repetition]
    )

    content = msg_params[:content].to_s.strip
    if content.blank?
      redirect_to root_path(anchor: "ai-copilot-panel"), alert: t("ai_chat_messages.controller.blank_message")
      return
    end

    include_lunch = ActiveModel::Type::Boolean.new.cast(msg_params[:include_lunch])
    include_dinner = ActiveModel::Type::Boolean.new.cast(msg_params[:include_dinner])
    days_scope = msg_params[:days_scope].presence || "weekdays"
    days_scope = "none" if !include_lunch && !include_dinner

    parameters = {
      "days_scope" => days_scope,
      "include_lunch" => days_scope == "none" ? false : include_lunch,
      "include_dinner" => days_scope == "none" ? false : include_dinner,
      "avoid_repetition" => ActiveModel::Type::Boolean.new.cast(msg_params[:avoid_repetition])
    }

    AiCopilotService.new.converse!(
      session: chat_session,
      user_message: content,
      parameters: parameters
    )

    redirect_to root_path(anchor: "ai-copilot-panel")
  rescue GeminiClient::ConfigurationError
    redirect_to root_path(anchor: "ai-copilot-panel"), alert: t("ai_chat_messages.controller.missing_api_key")
  rescue GeminiClient::ApiError
    redirect_to root_path(anchor: "ai-copilot-panel"), alert: t("ai_chat_messages.controller.api_error")
  end
end
