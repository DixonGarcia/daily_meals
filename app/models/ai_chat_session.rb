# Represents a persisted conversational planning session with the Gemini AI Copilot.
class AiChatSession < ApplicationRecord
  STATUSES = %w[active applied].freeze

  DEFAULT_PARAMETERS = {
    "days_scope" => "weekdays",
    "include_lunch" => true,
    "include_dinner" => true,
    "avoid_repetition" => true
  }.freeze

  has_many :ai_chat_messages, -> { order(:created_at, :id) }, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Checks whether the session is currently active (not yet applied to the calendar).
  #
  # @return [Boolean]
  def active?
    status == "active"
  end

  # Checks whether the session's proposed plan has been loaded into the weekly calendar.
  #
  # @return [Boolean]
  def applied?
    status == "applied"
  end

  # Returns the merged planning parameters with defaults guaranteed.
  #
  # @return [Hash]
  def effective_parameters
    DEFAULT_PARAMETERS.merge((parameters || {}).stringify_keys)
  end
end
