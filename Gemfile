source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Monitoring and HTTP checking
gem "httparty", "~> 0.21.0"
gem "net-ping", "~> 2.0.0"
gem "timeout", "~> 0.4.0"
gem "csv", "~> 3.2.0"

# SSL certificate checking
gem "openssl", "~> 3.0"

# Alerting services
gem "slack-notifier", "~> 2.4.0"
gem "twilio-ruby", "~> 7.6.4"
gem "mail", "~> 2.8.0"

# Data storage and reporting
gem "activerecord-import", "~> 1.6.0"
gem "chartkick", "~> 5.0.0"
gem "groupdate", "~> 6.0.0"

# Background job processing
gem "sidekiq", "~> 7.2.0"
gem "redis", "~> 5.0.0"
gem "sidekiq-cron", "~> 1.12.0"

# Authentication and authorization
gem "devise", "~> 4.9.0"
gem "pundit", "~> 2.3.0"

# API documentation
# gem "rswag-api", "~> 2.13.0"
# gem "rswag-ui", "~> 2.13.0"
# gem "rswag-specs", "~> 2.13.0"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  
  # Testing
  gem "rspec-rails", "~> 6.0.0"
  gem "factory_bot_rails", "~> 6.4.0"
  gem "faker", "~> 3.2.0"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  
  # Better error pages
  gem "better_errors", "~> 2.10.0"
  gem "binding_of_caller", "~> 1.0.0"
  
  # Database tools
  # gem "annotate", "~> 3.2.0"
  # gem "bullet", "~> 7.0.0"
end
