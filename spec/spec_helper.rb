require 'fileutils'
require 'travis/build'

require 'support/matchers'
require 'support/mock_shell'
require 'support/payloads'

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

module SpecHelpers
  CONST = {}

  def tmp_folder
    if ENV['TEST_ENV_NUMBER'].nil? || ENV['TEST_ENV_NUMBER'].empty?
      'tmp/default_env'
    else
      "tmp/env_#{ENV['TEST_ENV_NUMBER']}"
    end
  end

  def example_folder
    "#{tmp_folder}/examples"
  end

  def replace_consts
    replace_const 'Travis::Build::Script::TEMPLATES_PATH', 'spec/templates'
    replace_const 'Travis::Build::HOME_DIR', '.'
    replace_const 'Travis::Build::BUILD_DIR', "./#{tmp_folder}"
  end

  def replace_const(const, value)
    CONST[const] = eval(const).dup
    eval "#{const}.replace(#{value.inspect})"
  end

  def restore_consts
    CONST.each do |name, value|
      eval "#{name}.replace(#{value.inspect})"
    end
  end

  def executable(name)
    file(name, "builtin echo #{name} $@;")
    FileUtils.chmod('+x', "#{tmp_folder}/#{name}")
  end

  def file(name, content = '')
    path = "#{tmp_folder}/#{name}"
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w+') { |f| f.write(content) }
  end

  def directory(name)
    path = "#{tmp_folder}/#{name}"
    FileUtils.mkdir_p(path)
  end

  def gemfile(name)
    file(name)
    data['config']['gemfile'] = name
  end

  def store_example(name = nil)
    restore_consts
    name = [described_class.name.split('::').last.gsub(/([A-Z]+)/,'_\1').gsub(/^_/, '').downcase, name].compact.join('_').gsub(' ', '_')
    script = described_class.new(data, options).compile
    File.open("#{example_folder}/build_#{name}.sh", 'w+') { |f| f.write(script) }
  end
end

RSpec.configure do |c|
  c.include SpecHelpers
  c.deprecation_stream = 'rspec.log'
  c.mock_with :mocha
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
  # c.backtrace_clean_patterns.clear

  c.before :each do
    FileUtils.rm_rf tmp_folder
    FileUtils.mkdir_p tmp_folder
    FileUtils.rm_rf example_folder
    FileUtils.mkdir_p example_folder
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
