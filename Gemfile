source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "blueprinter", "~> 1.1"
gem "faraday", "~> 2.0"
gem "rack-cors"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "standard", require: false
  gem "rubocop-rails", require: false
end

group :test do
  gem "mocha"
  gem "webmock"
  gem "simplecov", require: false
  gem "simplecov-lcov", require: false
  gem "shoulda-matchers"
end
