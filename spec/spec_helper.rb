require 'fileutils'
require 'sinatra/test_helpers'

require 'travis/build'

require 'support/matchers/script'
require 'support/matchers/sexp'
require 'support/payloads'
require 'support/ssh_key'
require 'support/spec_helpers/node'
require 'support/spec_helpers/payload'
require 'support/spec_helpers/sexp'
require 'support/spec_helpers/shell'
require 'support/spec_helpers/store_example'

require 'script/shared/env'
require 'script/shared/git'
require 'script/shared/jdk'
require 'script/shared/jvm'
require 'script/shared/script'

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
