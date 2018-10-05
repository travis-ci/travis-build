source 'https://rubygems.org'

ruby File.read(File.expand_path('../.ruby-version', __FILE__)).strip if ENV.key?('DYNO')

gem 'activesupport', '~> 4.0'
gem 'addressable', '~> 2.3'
gem 'coder'
gem 'faraday'
gem 'faraday_middleware'
gem 'jemalloc', git: 'https://github.com/joshk/jemalloc-rb'
gem 'jwt', '~> 1.5'
gem 'metriks', '0.9.9.6'
gem 'metriks-librato_metrics', git: 'https://github.com/eric/metriks-librato_metrics'
gem 'minitar'
gem 'parallel_tests', group: %i[development test]
gem 'puma'
gem 'rack-ssl', '~> 1.4'
gem 'rake'
gem 'sentry-raven'
gem 'sinatra', '~> 1.4'
gem 'travis'
gem 'travis-config', '1.0.13'
gem 'travis-github_apps', git: 'https://github.com/travis-ci/travis-github_apps'
gem 'travis-rollout', git: 'https://github.com/travis-ci/travis-rollout'
gem 'travis-support', git: 'https://github.com/travis-ci/travis-support'

group :development do
  gem 'rerun'
end

group :test do
  gem 'codeclimate-test-reporter', require: nil
  gem 'mocha'
  gem 'pry'
  gem 'rspec'
  gem 'simplecov', require: false
  gem 'sinatra-contrib'
end
