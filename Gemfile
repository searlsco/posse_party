source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails"

# Model stuff
gem "pg"

# Networking stuff
gem "puma"
gem "rack-cors", require: "rack/cors"

# Background stuff
gem "solid_queue"
gem "aws-sdk-sesv2"
gem "actioncable-enhanced-postgresql-adapter"

# Feed stuff
gem "httparty"
gem "feedjira"
gem "reverse_markdown"
gem "redcarpet"

# Platform Integrations
gem "bskyrb"
gem "didkit"
gem "x"
gem "twitter-text", require: false
# mastodon-api gem removed - incompatible with Ruby 3.4 (uses httparty directly instead)

# Engine stuff
gem "searls-auth"
gem "bcrypt", "~> 3.1"
gem "mission_control-jobs"

# Frontend stuff
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "geared_pagination"

# Handy stuff
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv-rails"
  gem "good_migrations"

  gem "standard", require: false
  gem "standard-rails", require: false
  gem "brakeman", require: false

  gem "awesome_print"
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "capybara"
  gem "capybara-playwright-driver"
  gem "mocktail"
  gem "simplecov", require: false

  gem "vcr"
  gem "webmock"
end
