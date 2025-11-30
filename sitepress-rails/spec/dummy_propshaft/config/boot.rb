# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../../Gemfile', __dir__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)

# Prevent Sprockets from loading - we're using Propshaft in this dummy app
# Create a stub module to prevent errors when sprockets-rails tries to load
module Sprockets
  class Railtie
    def self.inherited(subclass); end
  end
end

# Mark sprockets as already loaded so it won't be required again
$LOADED_FEATURES << 'sprockets'
$LOADED_FEATURES << 'sprockets/railtie'
