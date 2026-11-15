ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Lightweight .env loader for local development without external gem dependencies.
env_file = File.expand_path("../.env", __dir__)
if File.exist?(env_file)
  File.readlines(env_file, chomp: true).each do |line|
    stripped = line.strip
    next if stripped.empty? || stripped.start_with?("#")

    key, value = stripped.split("=", 2)
    next if key.nil? || key.empty?

    ENV[key.strip] ||= value.to_s.strip
  end
end
