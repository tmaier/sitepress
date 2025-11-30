require_relative 'boot'

require "action_controller/railtie"
require "action_mailer/railtie"
require "propshaft"

Bundler.require(*Rails.groups)
require "sitepress-rails"

module DummyPropshaft
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Configure Propshaft asset paths
    config.assets.paths << Rails.root.join("app/content/assets") if Rails.root.join("app/content/assets").exist?
  end
end

