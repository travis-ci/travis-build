require 'simplecov'
require 'fileutils'
require 'sinatra/test_helpers'
require 'travis/build'
require 'pathname'

paths = ['spec/spec_helpers', 'spec/support', 'spec/**/shared']
paths = "{#{paths.join(',')}}/**/*.rb"
Dir[paths].each { |file| load file }

integration_enabled = ENV['INTEGRATION_SPECS'] == '1'
ENV['TOP'] = `git rev-parse --show-toplevel`.strip if integration_enabled

RSpec.configure do |c|
  c.include SpecHelpers::Logger
  c.include SpecHelpers::Payload
  c.include SpecHelpers::Node, :include_node_helpers
  c.include SpecHelpers::Sexp, :sexp
  c.include SpecHelpers::Shell, :script
  c.include SpecHelpers::StoreExample, :sexp
  c.include Sinatra::TestHelpers, :include_sinatra_helpers

  c.mock_with :mocha
  # c.backtrace_clean_patterns.clear

  c.filter_run_excluding(integration: true) unless integration_enabled
end
