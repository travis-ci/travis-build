def timeout_for(stage)
  Travis::Build::Data::DEFAULTS[:timeouts][stage]
end

def runs?(lines, cmd)
  cmd = /^#{Regexp.escape(cmd)}/ if cmd.is_a?(String)
  lines.detect { |line| line =~ cmd }
end

def echoes?(lines, cmd)
  runs? lines, "echo $ #{cmd}"
end

def folds?(lines, cmd, name)
  ix_start = lines.index { |line| line =~ /^echo travis_fold:start:#{Regexp.escape(name)}/ }
  ix_end   = lines.index { |line| line =~ /^echo travis_fold:end:#{Regexp.escape(name)}/ }
  ix_start && ix_end && lines[ix_start..ix_end].index { |line| line == cmd }
end

def logs?(lines, cmd)
  # cmd = /^output from #{Regexp.escape(cmd)}/
  # lines = File.read('tmp/build.log').split("\n")
  # lines.detect { |line| line =~ cmd }
  true
end

def timeouts?(lines, cmd, timeout = '')
  cmd = /^#{Regexp.escape(cmd)}/ if cmd.is_a?(String)
  ix = lines.index { |line| line =~ cmd }
  ix && lines[ix + 1] =~ /^travis_timeout #{timeout}/
end

def asserts?(lines, cmd)
  cmd = /^#{Regexp.escape(cmd)}/ if cmd.is_a?(String)
  ix = lines.index { |line| line =~ cmd }
  ix = ix + 1 if timeouts?(lines, cmd)
  ix && lines[ix + 1] == "travis_assert"
end

def log_for(script)
  File.open('tmp/build.sh', 'w+') { |f| f.write(script) } unless File.exists?('tmp/build.sh')
  system("/bin/bash tmp/build.sh > tmp/build.log 2>&1") unless File.exists?('tmp/build.log')
  File.read('tmp/build.log')
end

def env_for(script)
  log_for(script).split('-- env --').last
end

RSpec::Matchers.define :setup do |cmd, options = {}|
  match do |script|
    options = options.merge(echo: true, log: true, assert: true)
    failure_message_for_should do
      "expected script to setup #{cmd.inspect} with #{options} but it didn't:\n#{log_for(script)}"
    end
    script.should run cmd, options
  end
end

RSpec::Matchers.define :announce do |cmd, options = {}|
  match do |script|
    options = options.merge(echo: true, log: true)
    failure_message_for_should do
      "expected script to announce #{cmd.inspect} with #{options} but it didn't:\n#{log_for(script)}"
    end
    script.should run cmd, options
  end
end

RSpec::Matchers.define :install do |cmd, options = {}|
  match do |script|
    options = options.merge(echo: true, log: true, assert: true, timeout: timeout_for(:install))
    failure_message_for_should do
      "expected script to install #{cmd.inspect} with #{options} but it didn't:\n#{log_for(script)}"
    end
    script.should run cmd, options
  end
end

RSpec::Matchers.define :run_script do |cmd, options = {}|
  match do |script|
    options = options.merge(echo: true, log: true, timeout: timeout_for(:script))
    failure_message_for_should do
      "expected script to run the script #{cmd.inspect} with #{options} but it didn't:\n#{log_for(script)}"
    end
    script.should run cmd, options
  end
end

RSpec::Matchers.define :run do |cmd, options = {}|
  match do |script|
    lines = log_for(script).split("\n")

    failure_message_for_should do
      "expected script to run #{cmd.inspect} with #{options} but it didn't:\n#{lines.join("\n")}"
    end

    runs?(lines, cmd) &&
    (!options[:log]     || logs?(lines, cmd)) &&
    (!options[:echo]    || echoes?(lines, cmd)) &&
    (!options[:assert]  || asserts?(lines, cmd)) &&
    (!options[:timeout] || timeouts?(lines, cmd, options[:timeout]))
  end
end

RSpec::Matchers.define :set do |name, value|
  match do |script|
    env = env_for(script)

    failure_message_for_should do
      "expected script to set #{name} to #{value} but it didn't:\n#{env}"
    end

    env =~ /^#{name}=#{value.is_a?(String) ? Regexp.escape(value) : value}$/
  end
end

RSpec::Matchers.define :echo do |string|
  match do |script|
    lines = log_for(script).split("\n")

    failure_message_for_should do
      "expected script to echo #{string} but it didn't:\n#{script}"
    end

    echoes?(lines, string)
  end
end

RSpec::Matchers.define :fold do |cmd, name|
  match do |script|
    lines = log_for(script).split("\n")

    failure_message_for_should do
      "expected the script to mark #{cmd} with fold markers named #{name.inspect}"
    end

    folds?(lines, cmd, name)
  end
end
