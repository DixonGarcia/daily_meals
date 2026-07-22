# Base controller for API version 1.
# Handles bearer token authorization and last used timestamps updating.
class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_api_key!

  private

  # Validates the API key from the Authorization: Bearer token header.
  # Hashes the plain token and matches against the stored token_digest.
  #
  # @return [void]
  # @raise [ActionController::HttpAuthentication::Token::Error] if unauthorized
  def authenticate_api_key!
    authenticate_with_http_token do |token, options|
      digest = Digest::SHA256.hexdigest(token)
      @api_key = ApiKey.find_by(token_digest: digest, active: true)

      if @api_key
        @api_key.update!(last_used_at: Time.current)
        true
      else
        false
      end
    end || head(:unauthorized)
  end
end
