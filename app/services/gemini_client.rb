require "net/http"
require "uri"
require "json"

# HTTP client for interacting with the Google Gemini REST API using Structured Outputs.
# Reads credentials strictly from server-side environment variables.
class GeminiClient
  class ConfigurationError < StandardError; end
  class ApiError < StandardError; end

  API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models".freeze
  DEFAULT_MODEL = "gemini-2.5-flash".freeze

  RESPONSE_SCHEMA = {
    type: "OBJECT",
    properties: {
      reply: {
        type: "STRING",
        description: "Conversational response in Spanish explaining the menu proposal or answering the user."
      },
      meal_plan: {
        type: "ARRAY",
        description: "Proposed weekly schedule using dish IDs from the catalog.",
        items: {
          type: "OBJECT",
          properties: {
            day: { type: "STRING" },
            lunch_dish_id: { type: "INTEGER", nullable: true },
            dinner_dish_id: { type: "INTEGER", nullable: true }
          },
          required: %w[day]
        }
      }
    },
    required: %w[reply meal_plan]
  }.freeze

  # Initializes the GeminiClient with server-side credentials.
  #
  # @param api_key [String, nil] Optional override for GEMINI_API_KEY.
  # @param model [String, nil] Optional override for GEMINI_MODEL.
  def initialize(api_key: nil, model: nil)
    @api_key = api_key.nil? ? resolve_env("GEMINI_API_KEY") : api_key.to_s
    @model = (model.presence || resolve_env("GEMINI_MODEL").presence || DEFAULT_MODEL).to_s
  end

  # Sends the conversation history and system instruction to Gemini and parses the structured JSON response.
  #
  # @param system_instruction [String] System prompt containing dish catalog and planning parameters.
  # @param messages [Array<Hash>] Array of message hashes with :role ("user" or "assistant") and :content.
  # @return [Hash] Parsed hash with :reply (String) and :meal_plan (Array<Hash>).
  # @raise [ConfigurationError] if GEMINI_API_KEY is not configured.
  # @raise [ApiError] if the HTTP request fails or returns malformed output.
  def generate_plan_response(system_instruction:, messages:)
    raise ConfigurationError, "GEMINI_API_KEY is missing" if @api_key.blank?

    uri = URI.parse("#{API_BASE_URL}/#{@model}:generateContent")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 25

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["x-goog-api-key"] = @api_key
    request.body = build_request_body(system_instruction, messages).to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "Gemini API returned HTTP #{response.code}"
    end

    parse_response_body(response.body)
  rescue JSON::ParserError, SocketError, Timeout::Error, Errno::ECONNREFUSED => e
    raise ApiError, e.message
  end

  private

  # Builds the Gemini generateContent request payload with structured output schema.
  #
  # @param system_instruction [String]
  # @param messages [Array<Hash>]
  # @return [Hash]
  def build_request_body(system_instruction, messages)
    contents = messages.map do |msg|
      role = msg[:role].to_s == "assistant" ? "model" : "user"
      {
        role: role,
        parts: [{ text: msg[:content].to_s }]
      }
    end

    {
      systemInstruction: {
        parts: [{ text: system_instruction }]
      },
      contents: contents,
      generationConfig: {
        temperature: 0.4,
        responseMimeType: "application/json",
        responseSchema: RESPONSE_SCHEMA
      }
    }
  end

  # Extracts and parses the JSON text candidate from Gemini's response payload.
  #
  # @param raw_body [String]
  # @return [Hash]
  def parse_response_body(raw_body)
    outer = JSON.parse(raw_body)
    text_payload = outer.dig("candidates", 0, "content", "parts", 0, "text")
    raise ApiError, "Empty response candidate from Gemini" if text_payload.blank?

    parsed = JSON.parse(text_payload)
    {
      reply: parsed["reply"].to_s,
      meal_plan: Array(parsed["meal_plan"])
    }
  end

  # Reads an environment variable with a development hot-read fallback from .env.
  #
  # @param key [String]
  # @return [String]
  def resolve_env(key)
    val = ENV[key]
    return val.to_s if val.present?

    if Rails.env.development?
      env_path = Rails.root.join(".env")
      if File.exist?(env_path)
        File.readlines(env_path, chomp: true).each do |line|
          k, v = line.strip.split("=", 2)
          return v.to_s.strip if k == key
        end
      end
    end

    ""
  end
end
