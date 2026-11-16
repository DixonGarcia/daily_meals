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

  INGREDIENT_ITEM_SCHEMA = {
    type: "OBJECT",
    properties: {
      name: { type: "STRING" },
      supermarket_section: { type: "STRING" },
      suggested_quantity: { type: "STRING" }
    },
    required: %w[name supermarket_section suggested_quantity]
  }.freeze

  RESPONSE_SCHEMA = {
    type: "OBJECT",
    properties: {
      reply: {
        type: "STRING",
        description: "Conversational response in Spanish explaining the menu proposal, new dishes, or answering the user."
      },
      new_dishes: {
        type: "ARRAY",
        description: "New dishes with their ingredients to be created in the catalog if they do not exist yet.",
        items: {
          type: "OBJECT",
          properties: {
            name: { type: "STRING" },
            categories: {
              type: "ARRAY",
              description: "One or more applicable meal categories from: Breakfast, Lunch, Dinner, Snack, Other.",
              items: { type: "STRING" }
            },
            category: { type: "STRING" },
            ingredients: {
              type: "ARRAY",
              items: INGREDIENT_ITEM_SCHEMA
            }
          },
          required: %w[name categories ingredients]
        }
      },
      meal_plan: {
        type: "ARRAY",
        description: "Proposed weekly schedule using existing dish IDs or new dish names.",
        items: {
          type: "OBJECT",
          properties: {
            day: { type: "STRING" },
            lunch_dish_id: { type: "INTEGER", nullable: true },
            dinner_dish_id: { type: "INTEGER", nullable: true },
            lunch_new_dish_name: { type: "STRING", nullable: true },
            dinner_new_dish_name: { type: "STRING", nullable: true }
          },
          required: %w[day]
        }
      }
    },
    required: %w[reply new_dishes meal_plan]
  }.freeze

  DISH_SUGGESTION_SCHEMA = {
    type: "OBJECT",
    properties: {
      categories: {
        type: "ARRAY",
        description: "One or more meal categories from: Breakfast, Lunch, Dinner, Snack, Other.",
        items: { type: "STRING" }
      },
      category: { type: "STRING" },
      ingredients: {
        type: "ARRAY",
        items: INGREDIENT_ITEM_SCHEMA
      }
    },
    required: %w[categories ingredients]
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
  # @return [Hash] Parsed hash with :reply (String), :new_dishes (Array<Hash>), and :meal_plan (Array<Hash>).
  # @raise [ConfigurationError] if GEMINI_API_KEY is not configured.
  # @raise [ApiError] if the HTTP request fails or returns malformed output.
  def generate_plan_response(system_instruction:, messages:)
    payload_json = build_request_body(system_instruction, messages, RESPONSE_SCHEMA).to_json
    parsed = execute_structured_request(payload_json)

    {
      reply: parsed["reply"].to_s,
      new_dishes: Array(parsed["new_dishes"]),
      meal_plan: Array(parsed["meal_plan"])
    }
  end

  # Requests an AI-generated category and ingredient list for a given dish name.
  #
  # @param dish_name [String] The Spanish name of the dish.
  # @param existing_ingredients [Array<Hash>] Existing ingredients with :name and :supermarket_section.
  # @return [Hash] Hash with :category (String) and :ingredients (Array<Hash>).
  def suggest_dish_ingredients(dish_name:, existing_ingredients:)
    system_instruction = <<~PROMPT
      You are the DailyMeals Culinary Assistant. Given a dish name in Spanish, suggest its applicable meal categories (one or more from: #{Dish::CATEGORIES.join(', ')}) and a practical list of supermarket ingredients with quantities for 2 to 4 servings.
      - Include all applicable `categories` (e.g., if a dish works for both Lunch and Dinner, return ["Lunch", "Dinner"]).
      - Allowed `supermarket_section` values: #{Ingredient::SECTIONS.join(', ')}.
      - Whenever an ingredient matches one in EXISTING_INGREDIENTS below, reuse its exact `name` and `supermarket_section`.
      - All ingredient names and quantities must be in Spanish (e.g., "500g", "1 lata", "2 unidades").

      EXISTING_INGREDIENTS:
      #{existing_ingredients.to_json}
    PROMPT

    messages = [ { role: "user", content: "Sugiere las categorías e ingredientes para el plato: #{dish_name}" } ]
    payload_json = build_request_body(system_instruction, messages, DISH_SUGGESTION_SCHEMA).to_json
    parsed = execute_structured_request(payload_json)

    cats = Array(parsed["categories"]).presence || [ parsed["category"] ].compact
    {
      categories: cats.map(&:to_s),
      category: cats.first.to_s,
      ingredients: Array(parsed["ingredients"])
    }
  end

  private

  # Executes a structured generation request with model fallback and returns the parsed JSON Hash.
  #
  # @param payload_json [String]
  # @return [Hash]
  def execute_structured_request(payload_json)
    raise ConfigurationError, "GEMINI_API_KEY is missing" if @api_key.blank?

    candidate_models = ([ @model ] + FALLBACK_MODELS).uniq

    response = nil
    candidate_models.each do |candidate|
      response = post_generate_content(candidate, payload_json)
      break unless RETRYABLE_STATUS_CODES.include?(response.code.to_s)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "Gemini API returned HTTP #{response.code}"
    end

    parse_json_candidate(response.body)
  rescue JSON::ParserError, SocketError, Timeout::Error, Errno::ECONNREFUSED => e
    raise ApiError, e.message
  end

  # Executes the HTTPS POST request against the given Gemini model endpoint.
  #
  # @param target_model [String]
  # @param payload_json [String]
  # @return [Net::HTTPResponse]
  def post_generate_content(target_model, payload_json)
    uri = URI.parse("#{API_BASE_URL}/#{target_model}:generateContent")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 45

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["x-goog-api-key"] = @api_key
    request.body = payload_json

    http.request(request)
  end

  # Builds the Gemini generateContent request payload with the specified structured output schema.
  #
  # @param system_instruction [String]
  # @param messages [Array<Hash>]
  # @param schema [Hash]
  # @return [Hash]
  def build_request_body(system_instruction, messages, schema = RESPONSE_SCHEMA)
    contents = messages.map do |msg|
      role = msg[:role].to_s == "assistant" ? "model" : "user"
      {
        role: role,
        parts: [ { text: msg[:content].to_s } ]
      }
    end

    {
      systemInstruction: {
        parts: [ { text: system_instruction } ]
      },
      contents: contents,
      generationConfig: {
        temperature: 0.4,
        responseMimeType: "application/json",
        responseSchema: schema
      }
    }
  end

  # Extracts and parses the JSON text candidate from Gemini's response payload.
  #
  # @param raw_body [String]
  # @return [Hash]
  def parse_json_candidate(raw_body)
    utf8_body = raw_body.to_s.dup.force_encoding(Encoding::UTF_8)
    outer = JSON.parse(utf8_body)
    text_payload = outer.dig("candidates", 0, "content", "parts", 0, "text")
    raise ApiError, "Empty response candidate from Gemini" if text_payload.blank?

    JSON.parse(text_payload.to_s.dup.force_encoding(Encoding::UTF_8))
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
