ENV['ENV'] = 'test'

require 'simplecov'
require 'fileutils'
require 'sinatra/test_helpers'
require 'travis/build'
require 'pathname'

Dir["{spec/spec_helpers,spec/support,spec/**/shared}/**/*.rb"].each do |f|
  load(f)
end

module SpecHelpers
  def top
    @top ||= Pathname.new(`git rev-parse --show-toplevel`.strip)
  end

  module_function :top

  def integration?
    ENV['INTEGRATION_SPECS'] == '1'
  end

  module_function :integration?
end

RSpec.configure do |c|
  c.include SpecHelpers::Logger
  c.include SpecHelpers::Payload
  c.include SpecHelpers::Node, :include_node_helpers
  c.include SpecHelpers::Sexp, :sexp
  c.include SpecHelpers::Shell, :script
  c.include Sinatra::TestHelpers, :include_sinatra_helpers

  c.mock_with :mocha

  c.filter_run_excluding(integration: true) unless SpecHelpers.integration?
  c.filter_run_excluding(example: true)
end
