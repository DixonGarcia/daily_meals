# Centralized environment variable lookup with safe local .env fallback in development.
# Replaces duplicate manual .env parsers across ApplicationController and GeminiClient.
module EnvResolver
  # Fetches an environment variable by key.
  # In development, optionally prioritizes the local .env file for hot-reloading secrets
  # or falls back to .env when ENV[key] is unset.
  #
  # @param key [String] The environment variable name to resolve.
  # @param prefer_dotenv [Boolean] When true in development, check .env before ENV.
  # @return [String] The resolved value or empty string if unset.
  def self.fetch(key, prefer_dotenv: false)
    if prefer_dotenv && Rails.env.development?
      dotenv_val = read_from_dotenv(key)
      return dotenv_val if dotenv_val.present?
    end

    env_val = ENV[key]
    return env_val.to_s unless env_val.nil?

    return read_from_dotenv(key).to_s if Rails.env.development?

    ""
  end

  # Reads a single key from the project's .env file, skipping comments and blank lines.
  #
  # @param key [String] The environment variable name to locate.
  # @return [String, nil]
  def self.read_from_dotenv(key)
    env_path = Rails.root.join(".env")
    return nil unless File.exist?(env_path)

    File.readlines(env_path, chomp: true).each do |line|
      stripped = line.strip
      next if stripped.empty? || stripped.start_with?("#")

      k, v = stripped.split("=", 2)
      return v.to_s.strip if k&.strip == key
    end

    nil
  end
  private_class_method :read_from_dotenv
end
