require 'fileutils'
require 'travis/build'

require 'support/matchers'
require 'support/mock_shell'
require 'support/payloads'
require 'support/spec_helpers'

require 'shared/git'
require 'shared/jdk'
require 'shared/jvm'
require 'shared/script'
require 'shared/env_vars'

STDOUT.sync = true

class Hash
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

RSpec.configure do |c|
  c.include SpecHelpers
  c.mock_with :mocha
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
  # c.backtrace_clean_patterns.clear

  c.before :each do
    FileUtils.rm_rf 'tmp'
    FileUtils.mkdir 'tmp'
    FileUtils.rm_rf 'examples'
    FileUtils.mkdir 'examples'
  end

  c.before :each do
    replace_consts
  end

  c.after :each do
    restore_consts
  end
end

class RSpec::Core::Example
  def passed?
    @exception.nil?
  end

  def failed?
    !passed?
  end
end
