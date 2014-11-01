require 'fileutils'
require 'travis/build'

require 'support/matchers'
require 'support/payloads'
require 'support/ssh_key'
require 'support/spec_helpers/node'
require 'support/spec_helpers/sexp'
require 'support/spec_helpers/store_example'

require 'sexp/shared/env'
require 'sexp/shared/git'
require 'sexp/shared/jdk'
require 'sexp/shared/jvm'
require 'sexp/shared/script'

class Hash
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

RSpec.configure do |c|
  c.include SpecHelpers::Node, :include_node_helpers
  c.include SpecHelpers::Sexp, :sexp
  c.include SpecHelpers::StoreExample, :sexp

  c.mock_with :mocha
end
