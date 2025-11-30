source 'https://rubygems.org'

gemspec path: "sitepress"
gemspec path: "sitepress-cli"
gemspec path: "sitepress-core"
gemspec path: "sitepress-rails"
gemspec path: "sitepress-server"

gem "appraisal", "~> 2.0"

group :test do
  gem "pry", require: nil
  gem "rack-test", require: nil
end

# Asset pipeline gems - for testing with different asset pipelines
# Use BUNDLE_WITHOUT to exclude unwanted pipelines, e.g.:
#   BUNDLE_WITHOUT=propshaft:importmaps bundle install
# Or set ASSET_PIPELINE env var at runtime

# Sprockets (default)
group :sprockets do
  gem "sprockets-rails", ">= 2.0.0"
end

# Propshaft support
group :propshaft do
  gem "propshaft"
end

# Importmaps support
group :importmaps do
  gem "importmap-rails"
end

gem "base64", "~> 0.2.0"

gem "bigdecimal", "~> 3.1"

gem "mutex_m", "~> 0.3.0"

gem "drb", "~> 2.2"
