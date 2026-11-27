require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DailyMeals
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2
    config.active_support.to_time_preserves_timezone = :zone

    # Set default locale to Spanish
    config.i18n.default_locale = :es

    # Support mounting DailyMeals under a domain subpath (e.g., /daily_meals)
    relative_url_root = ENV["RAILS_RELATIVE_URL_ROOT"].to_s.strip
    config.relative_url_root = relative_url_root if relative_url_root.present?

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # All "today" and ISO-week calculations follow the household's local time (Caracas, UTC-4),
    # independently of the VPS location (Hetzner Helsinki).
    config.time_zone = "Caracas"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
