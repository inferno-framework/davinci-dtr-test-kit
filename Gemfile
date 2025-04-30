# frozen_string_literal: true

source "https://rubygems.org"

gem 'smart_app_launch_test_kit', git: 'https://github.com/inferno-framework/smart-app-launch-test-kit.git', branch: 'client_authorization_code_tests'
gem 'udap_security_test_kit', git: 'https://github.com/inferno-framework/udap-security-test-kit.git', branch: 'client_authorization_code_tests'

gemspec

group :development, :test do
  gem 'database_cleaner-sequel', '~> 1.8'
  gem 'factory_bot', '~> 6.1'
  gem 'rack-test', '~> 1.1.0'
  gem 'rspec', '~> 3.10'
  gem 'rubocop', '~> 1.9'
  gem 'webmock', '~> 3.11'
  gem 'rubocop-rspec', require: false
  gem "rubocop-rake", "~> 0.6.0"
  gem 'debug'
  gem 'builder'
end
