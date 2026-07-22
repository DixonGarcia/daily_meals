# Represents an API Key for authentication.
# Hashed digests are stored in the database, while the plain text token is only shown once to the user.
#
# @attr [String] name Custom label for the API Key.
# @attr [String] token_digest SHA256 hashed digest of the plain text token.
# @attr [Boolean] active Indicates if the key is enabled.
# @attr [ActiveSupport::TimeWithZone, nil] last_used_at Time when the key was last used.
class ApiKey < ApplicationRecord
  # Reader for the raw unhashed token (available only during creation)
  attr_reader :token

  before_validation :generate_token, on: :create

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  private

  # Generates a random secure token prefix and hashes it into token_digest.
  # e.g., "dmeal_live_..."
  #
  # @return [void]
  def generate_token
    return if token_digest.present?

    @token = "dmeal_live_#{SecureRandom.hex(24)}"
    self.token_digest = Digest::SHA256.hexdigest(@token)
  end
end
