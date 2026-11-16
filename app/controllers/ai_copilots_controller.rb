# Handles exporting the dish catalog and importing planned meals via AI copilot.
class AiCopilotsController < ApplicationController
  # GET /ai_copilot/export
  # Exports the catalog of dishes as JSON.
  # @return [void]
  def export
    restrictions = params[:restrictions]
    result = AiCopilotService.new.export_catalog(restrictions)
    render json: result
  end

  # POST /ai_copilot/import
  # Imports a weekly meal plan suggested by the AI copilot.
  # @return [void]
  def import
    payload = params.expect(:payload)
    if AiCopilotService.new.import_plan(payload)
      redirect_to root_path, notice: t("ai_copilots.controller.imported")
    else
      redirect_to root_path, alert: t("ai_copilots.controller.error_import")
    end
  end
end
