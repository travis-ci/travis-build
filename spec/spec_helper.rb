require 'fileutils'
require 'travis/build'

require 'sexp/shared/env'
require 'sexp/shared/git'
require 'sexp/shared/jdk'
require 'sexp/shared/jvm'
require 'sexp/shared/script'

require 'support/matchers'
require 'support/payloads'
require 'support/spec_helpers/node'
require 'support/spec_helpers/sexp'

class Hash
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

RSpec.configure do |c|
  c.include SpecHelpers::Node, :include_node_helpers
  c.include SpecHelpers::Sexp, :sexp
  c.mock_with :mocha
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
end
