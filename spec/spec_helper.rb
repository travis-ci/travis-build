require 'fileutils'
require 'travis/build'
require 'support/matchers'
require 'support/payloads'
require 'shared/jdk'
require 'shared/jvm'
require 'shared/script'

STDOUT.sync = true

class Hash
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

Travis::Build::Script::TEMPLATES_PATH.replace 'spec/templates'
Travis::Build::LOGS.replace(build: 'build.log', state: 'state.log')
Travis::Build::HOME_DIR.replace('.')

module SpecHelpers
  def executable(name)
    file(name, "builtin echo #{name} $@ >> test.log; builtin echo output from #{name} $@;")
    FileUtils.chmod('+x', "tmp/#{name}")
  end

  def file(name, content = '')
    path = "tmp/#{name}"
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w+') { |f| f.write(content) }
  end

  def gemfile(name)
    file(name)
    data['config']['gemfile'] = name
  end
end

RSpec.configure do |c|
  c.include SpecHelpers
  c.mock_with :mocha
  # c.backtrace_clean_patterns.clear

  c.before :each do
    FileUtils.rm_rf 'tmp'
    FileUtils.mkdir 'tmp'
  end

  c.after :each do
    puts subject if example.failed?
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
