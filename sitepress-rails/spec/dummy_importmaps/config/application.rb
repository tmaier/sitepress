require_relative 'boot'

require "action_controller/railtie"
require "action_mailer/railtie"
# No asset pipeline - using importmaps for JavaScript ESM modules

Bundler.require(*Rails.groups)
require "sitepress-rails"

module DummyImportmaps
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # No asset pipeline configuration needed - serving static files directly
  end
end

