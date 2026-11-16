require "net/http"
require "uri"
require "json"

# HTTP client for interacting with the Google Gemini REST API using Structured Outputs.
# Reads credentials strictly from server-side environment variables.
class GeminiClient
  class ConfigurationError < StandardError; end
  class ApiError < StandardError; end

  API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models".freeze
  DEFAULT_MODEL = "gemini-3.1-flash-lite".freeze
  FALLBACK_MODELS = %w[
    gemini-3.1-flash-lite
    gemini-flash-latest
    gemini-flash-lite-latest
    gemini-3.8-flash
    gemini-2.5-flash
  ].freeze
  RETRYABLE_STATUS_CODES = %w[404 429 500 502 503].freeze

  MODEL_ALIASES = {
    "gemini-3.1-flash" => "gemini-3.1-flash-lite"
  }.freeze

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
    raw_model = (model.presence || resolve_env("GEMINI_MODEL").presence || DEFAULT_MODEL).to_s
    cleaned = raw_model.sub(/\Amodels\//, "").strip
    @model = MODEL_ALIASES.fetch(cleaned, cleaned)
  end

  # Sends the conversation history and system instruction to Gemini and parses the structured JSON response.
  # Automatically falls back across FALLBACK_MODELS if a model identifier returns HTTP 404 or temporary 503/429.
  #
  # @param system_instruction [String] System prompt containing dish catalog and planning parameters.
  # @param messages [Array<Hash>] Array of message hashes with :role ("user" or "assistant") and :content.
  # @return [Hash] Parsed hash with :reply (String) and :meal_plan (Array<Hash>).
  # @raise [ConfigurationError] if GEMINI_API_KEY is not configured.
  # @raise [ApiError] if the HTTP request fails or returns malformed output.
  def generate_plan_response(system_instruction:, messages:)
    raise ConfigurationError, "GEMINI_API_KEY is missing" if @api_key.blank?

    payload_json = build_request_body(system_instruction, messages).to_json
    candidate_models = ([@model] + FALLBACK_MODELS).uniq

    response = nil
    candidate_models.each do |candidate|
      response = post_generate_content(candidate, payload_json)
      break unless RETRYABLE_STATUS_CODES.include?(response.code.to_s)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "Gemini API returned HTTP #{response.code}"
    end

    parse_response_body(response.body)
  rescue JSON::ParserError, SocketError, Timeout::Error, Errno::ECONNREFUSED => e
    raise ApiError, e.message
  end

  private

  # Executes the HTTPS POST request against the given Gemini model endpoint.
  #
  # @param target_model [String]
  # @param payload_json [String]
  # @return [Net::HTTPResponse]
  def post_generate_content(target_model, payload_json)
    uri = URI.parse("#{API_BASE_URL}/#{target_model}:generateContent")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 25

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["x-goog-api-key"] = @api_key
    request.body = payload_json

    http.request(request)
  end

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
    utf8_body = raw_body.to_s.dup.force_encoding(Encoding::UTF_8)
    outer = JSON.parse(utf8_body)
    text_payload = outer.dig("candidates", 0, "content", "parts", 0, "text")
    raise ApiError, "Empty response candidate from Gemini" if text_payload.blank?

    parsed = JSON.parse(text_payload.to_s.dup.force_encoding(Encoding::UTF_8))
    {
      reply: parsed["reply"].to_s,
      meal_plan: Array(parsed["meal_plan"])
    }
  end

  # Reads an environment variable with a development hot-read priority from .env.
  #
  # @param key [String]
  # @return [String]
  def resolve_env(key)
    if Rails.env.development?
      env_path = Rails.root.join(".env")
      if File.exist?(env_path)
        File.readlines(env_path, chomp: true).each do |line|
          stripped = line.strip
          next if stripped.empty? || stripped.start_with?("#")

          k, v = stripped.split("=", 2)
          return v.to_s.strip if k&.strip == key && v.to_s.strip.present?
        end
      end
    end

    ENV[key].to_s
  end
end
