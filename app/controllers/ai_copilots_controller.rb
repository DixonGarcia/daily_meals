class AiCopilotsController < ApplicationController
  protect_from_forgery except: [:export] # Allow easy JSON requests if client does it

  def export
    restrictions = params[:restrictions]
    result = AiCopilotService.new.export_catalog(restrictions)
    render json: result
  end

  def import
    payload = params[:payload]
    if AiCopilotService.new.import_plan(payload)
      redirect_to root_path, notice: 'AI meal plan imported successfully.'
    else
      redirect_to root_path, alert: 'Error importing the AI meal plan.'
    end
  end
end
