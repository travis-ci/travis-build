source 'https://rubygems.org'

ruby File.read(File.expand_path('../.ruby-version', __FILE__)).strip if ENV.key?('DYNO')

gem 'activesupport', '~> 4.0'
gem 'addressable', '~> 2.3'
gem 'coder'
gem 'jemalloc'
gem 'metriks', '0.9.9.6'
gem 'metriks-librato_metrics', github: 'eric/metriks-librato_metrics'
gem 'puma'
gem 'rack-ssl', '~> 1.4'
gem 'sentry-raven'
gem 'sinatra', '~> 1.4'
gem 'travis-support', github: 'travis-ci/travis-support'

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
