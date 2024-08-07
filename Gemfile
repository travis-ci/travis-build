# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(File.expand_path('.ruby-version', __dir__)).strip

gem 'activesupport', '~> 7'
gem 'addressable', '~> 2.3'
gem 'codeclimate-test-reporter', require: false, group: %i[development test]
gem 'coder'
gem 'connection_pool'
gem 'ed25519'
gem 'faraday'
gem 'faraday_middleware'
gem 'jemalloc', github: 'travis-ci/jemalloc-rb'
gem 'jwt', '~> 1.5'
gem 'metriks', '0.9.9.6'
gem 'metriks-librato_metrics', github: 'eric/metriks-librato_metrics'
gem 'minitar'
gem 'mocha', require: false, group: %i[development test]
gem 'parallel_tests', require: false, group: %i[development test]
gem 'pry', '>= 0.14.2', require: false, group: %i[development test]
gem 'webmock', group: :test
gem 'puma'
gem 'rack', '>= 2.2.4'
gem 'rack-ssl', '~> 1.4'
gem 'rack-test', '>= 2.1.0'
gem 'redis', '~> 4'
gem 'rake'
gem 'rbtrace'
gem 'rerun', require: false, group: :development
gem 'rspec', '~> 3.0', group: %i[development test]
gem 'rubocop', require: false, group: %i[development test]
gem 'sentry-raven'
gem 'simplecov', require: false, group: %i[development test]
gem 'sinatra', '>= 3.0.6'
gem 'ssh_data'
gem 'travis'
gem 'travis-config', github: 'travis-ci/travis-config'
gem 'travis-github_apps', git: 'https://github.com/travis-ci/travis-github_apps', branch: 'ga-ext_access'
gem 'travis-rollout', github: 'travis-ci/travis-rollout'
gem 'travis-support', github: 'travis-ci/travis-support'

gem "octokit", "~> 4.18"
gem 'rest-client'

github 'sinatra/sinatra' do
  gem 'sinatra-contrib'
end
