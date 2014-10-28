require 'fileutils'
require 'travis/build'

require 'support/matchers'
require 'support/payloads'
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

# RSpec.configure do |c|
#   c.include SpecHelpers
#   c.deprecation_stream = 'rspec.log'
#   c.mock_with :mocha
#   c.filter_run focus: true
#   c.run_all_when_everything_filtered = true
#   c.filter_run_excluding clean_room: true unless ENV['TRAVIS']
#   # c.formatter = 'documentation'
#   c.include Sinatra::TestHelpers, :include_sinatra_helpers
#   # c.backtrace_clean_patterns.clear
#
#   c.before :each do
#     FileUtils.rm_rf 'tmp'
#     FileUtils.mkdir 'tmp'
#     FileUtils.rm_rf 'examples'
#     FileUtils.mkdir 'examples'
#   end
#
#   c.before :each do
#     replace_consts
#   end
#
#   c.after :each do
#     restore_consts
#   end
# end
#
# class RSpec::Core::Example
#   def passed?
#     @exception.nil?
#   end
#
#   def failed?
#     !passed?
#   end
# end
