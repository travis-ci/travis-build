source 'https://rubygems.org'

ruby File.read(File.expand_path('../.ruby-version', __FILE__)).strip if ENV.key?('DYNO')

gem 'rake'
gem 'activesupport', '~> 4.0'
gem 'addressable', '~> 2.3'
gem 'jwt'
gem 'coder'
gem 'jemalloc', git: 'https://github.com/joshk/jemalloc-rb'
gem 'metriks', '0.9.9.6'
gem 'metriks-librato_metrics', git: 'https://github.com/eric/metriks-librato_metrics'
gem 'puma'
gem 'rack-ssl', '~> 1.4'
gem 'sentry-raven'
gem 'sinatra', '~> 1.4'
gem 'travis'
gem 'travis-config'
gem 'travis-rollout', git: 'https://github.com/travis-ci/travis-rollout', ref: 'sf-refactor'
gem 'travis-support', git: 'https://github.com/travis-ci/travis-support'

gem 'faraday'
gem 'faraday_middleware'

group :development do
  gem 'rerun'
end

group :test do
  gem 'codeclimate-test-reporter', require: nil
  gem 'mocha', '~> 0.10.0'
  gem 'pry'
  gem 'rspec', '~> 3.0'
  gem 'simplecov', require: false
  gem 'sinatra-contrib'
end
