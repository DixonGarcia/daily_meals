# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

relative_url_root = ENV["RAILS_RELATIVE_URL_ROOT"].to_s.strip.chomp("/")
if relative_url_root.present?
  map relative_url_root do
    run Rails.application
  end
else
  run Rails.application
end

Rails.application.load_server
