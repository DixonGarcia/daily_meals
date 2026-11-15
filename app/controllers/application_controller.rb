# Base controller class from which all other web controllers inherit.
# Enforces single-owner session authentication across the web interface.
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_authentication!
  helper_method :authenticated?

  private

  # Ensures the current browser holds a valid encrypted owner session cookie.
  # Redirects unauthenticated visitors to the login screen.
  #
  # @return [void]
  def require_authentication!
    return if authenticated?

    redirect_to new_session_path, alert: t("sessions.controller.unauthenticated")
  end

  # Verifies in constant time whether the encrypted owner_session cookie matches
  # the SHA-256 fingerprint of ENV["APP_ACCESS_PASSWORD"].
  # Fails closed (returns false) if ENV["APP_ACCESS_PASSWORD"] is blank.
  #
  # @return [Boolean] true if the current request is authenticated as the owner.
  def authenticated?
    expected_password = current_access_password
    return false if expected_password.blank?

    expected_digest = Digest::SHA256.hexdigest(expected_password)
    actual_digest = cookies.encrypted[:owner_session].to_s
    return false if actual_digest.blank?

    ActiveSupport::SecurityUtils.secure_compare(actual_digest, expected_digest)
  end

  # Reads the master access password from the environment (with development hot-read fallback from .env).
  #
  # @return [String]
  def current_access_password
    env_val = ENV["APP_ACCESS_PASSWORD"]
    return env_val.to_s unless env_val.nil?

    if Rails.env.development?
      env_path = Rails.root.join(".env")
      if File.exist?(env_path)
        File.readlines(env_path, chomp: true).each do |line|
          k, v = line.strip.split("=", 2)
          return v.to_s.strip if k == "APP_ACCESS_PASSWORD"
        end
      end
    end

    ""
  end
end
