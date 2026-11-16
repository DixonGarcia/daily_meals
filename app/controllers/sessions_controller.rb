# Handles single-owner authentication via master password and encrypted long-lived cookies.
class SessionsController < ApplicationController
  skip_before_action :require_authentication!, only: %i[new create]

  rate_limit to: 5, within: 15.minutes, only: :create, with: -> {
    redirect_to new_session_path, alert: t("sessions.controller.rate_limited")
  }

  # GET /session/new
  # Renders the minimalist vault login card, or redirects to root if already signed in.
  #
  # @return [void]
  def new
    redirect_to root_path if authenticated?
  end

  # POST /session
  # Validates the submitted master password in constant time and issues a 60-day encrypted cookie.
  #
  # @return [void]
  def create
    password = params.expect(:password).to_s
    expected = current_access_password

    if expected.present? && ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(password),
      Digest::SHA256.hexdigest(expected)
    )
      cookies.encrypted[:owner_session] = {
        value: Digest::SHA256.hexdigest(expected),
        expires: 60.days.from_now,
        httponly: true,
        same_site: :lax,
        secure: request.ssl?
      }
      redirect_to root_path, notice: t("sessions.controller.signed_in")
    else
      render_invalid_password
    end
  rescue ActionController::ParameterMissing
    render_invalid_password
  end

  # DELETE /session
  # Clears the encrypted owner session cookie and redirects to the login screen.
  #
  # @return [void]
  def destroy
    cookies.delete(:owner_session)
    redirect_to new_session_path, notice: t("sessions.controller.signed_out")
  end

  private

  # Renders the login form with a 422 status and localized error alert.
  #
  # @return [void]
  def render_invalid_password
    flash.now[:alert] = t("sessions.controller.invalid_password")
    render :new, status: :unprocessable_content
  end
end
