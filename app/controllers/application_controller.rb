# Base controller class from which all other web controllers inherit.
# Enforces single-owner session authentication across the web interface.
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_authentication!
  helper_method :authenticated?

  # Allows unauthenticated (read-only) guest access to the specified controller actions.
  #
  # @param only [Array<Symbol>, Symbol] action names accessible without signing in
  # @return [void]
  def self.allow_guest_access(only:)
    skip_before_action :require_authentication!, only: only
  end

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

  # Reads the master access password from the environment (with development .env fallback).
  #
  # @return [String]
  def current_access_password
    EnvResolver.fetch("APP_ACCESS_PASSWORD", prefer_dotenv: false)
  end

  # Resolves the active household servings count from cookie or persisted HouseholdSetting default.
  #
  # @param household_setting [HouseholdSetting] Optional preloaded setting instance.
  # @return [Integer]
  def current_household_servings(household_setting = HouseholdSetting.current_or_default)
    stored = cookies[:shopping_servings].to_i
    return stored if stored.between?(1, ShoppingListGenerator::MAX_SERVINGS)

    household_setting.servings_multiplier
  end
end
