# Manages persisted Gemini AI Copilot chat sessions and applies proposed weekly menus.
class AiChatSessionsController < ApplicationController
  before_action :set_chat_session, only: %i[switch apply destroy]

  # POST /ai_chat_sessions
  # Creates a new persisted chat session and sets it as active.
  #
  # @return [void]
  def create
    title = "#{t('ai_chat_sessions.default_title')} (#{Time.current.strftime('%d/%m %H:%M')})"
    chat_session = AiChatSession.create!(
      title: title,
      parameters: AiChatSession::DEFAULT_PARAMETERS
    )
    session[:active_ai_chat_session_id] = chat_session.id
    redirect_to root_path(anchor: "ai-copilot-panel"), notice: t("ai_chat_sessions.controller.created")
  end

  # PATCH /ai_chat_sessions/:id/switch
  # Switches the currently active chat session in the dashboard.
  #
  # @return [void]
  def switch
    session[:active_ai_chat_session_id] = @chat_session.id
    redirect_to root_path(anchor: "ai-copilot-panel")
  end

  # POST /ai_chat_sessions/:id/apply
  # Atomically loads the session's proposed menu and/or proposed new dishes and redirects appropriately.
  #
  # @return [void]
  def apply
    had_plan = @chat_session.proposed_plan.present? && @chat_session.effective_parameters["days_scope"] != "none"

    if AiCopilotService.new.apply_session_plan!(@chat_session, dish_overrides: params[:dish_overrides])
      if had_plan
        redirect_to root_path, notice: t("ai_chat_sessions.controller.applied")
      else
        redirect_to root_path(anchor: "ai-copilot-panel"), notice: t("ai_chat_sessions.controller.dishes_saved")
      end
    else
      redirect_to root_path(anchor: "ai-copilot-panel"), alert: t("ai_chat_sessions.controller.apply_error")
    end
  end

  # DELETE /ai_chat_sessions/:id
  # Removes a persisted chat session and its messages.
  #
  # @return [void]
  def destroy
    @chat_session.destroy!
    session.delete(:active_ai_chat_session_id) if session[:active_ai_chat_session_id] == @chat_session.id
    redirect_to root_path(anchor: "ai-copilot-panel"), notice: t("ai_chat_sessions.controller.deleted")
  end

  private

  # Finds the target AiChatSession by ID.
  #
  # @return [void]
  def set_chat_session
    @chat_session = AiChatSession.find(params.expect(:id))
  end
end
