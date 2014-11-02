require 'fileutils'
require 'sinatra/test_helpers'

require 'travis/build'

paths = ['spec/spec_helpers', 'spec/support', 'spec/script/shared']
paths = "{#{paths.join(',')}}/**/*.rb"
Dir[paths].each { |file| load file }

class Hash
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

RSpec.configure do |c|
  c.include SpecHelpers::Payload
  c.include SpecHelpers::Node, :include_node_helpers
  c.include SpecHelpers::Sexp, :sexp
  c.include SpecHelpers::Shell, :script
  c.include SpecHelpers::StoreExample, :sexp
  c.include Sinatra::TestHelpers, :include_sinatra_helpers

  c.mock_with :mocha
end
