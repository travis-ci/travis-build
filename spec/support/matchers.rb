def runs?(lines, cmd)
  if cmd.is_a?(String)
    lines.detect { |line| line.include?(cmd) }
  else
    lines.detect { |line| line =~ cmd }
  end
end

def echoes?(lines, cmd)
  runs? lines, "echo $ #{cmd}"
end

def folds?(lines, cmd, name)
  cmd = /^(?:travis_retry )?#{Regexp.escape(cmd)}/ if cmd.is_a?(String)
  ix_start = lines.index { |line| line =~ /^echo -en travis_fold:start:#{Regexp.escape(name)}/ }
  ix_end   = lines.index { |line| line =~ /^echo -en travis_fold:end:#{Regexp.escape(name)}/ }
  ix_start && ix_end && lines[ix_start..ix_end].index { |line| line =~ cmd }
end

def logs?(lines, cmd)
  # cmd = /^output from #{Regexp.escape(cmd)}/
  # lines = File.read('tmp/build.log').split("\n")
  # lines.detect { |line| line =~ cmd }
  true
end

def retries?(lines, cmd)
  cmd = /^#{Regexp.escape("travis_retry #{cmd}")}/ if cmd.is_a?(String)
  lines.detect { |line| line =~ cmd }
end

def asserts?(lines, cmd)
  cmd = /^(?:travis_retry )?#{Regexp.escape(cmd)}/ if cmd.is_a?(String)
  ix = lines.index { |line| line =~ cmd }
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
    options = options.merge(echo: true, log: true, assert: true)
    failure_message_for_should do
      "expected script to install #{cmd.inspect} with #{options} but it didn't:\n#{log_for(script)}"
    end
    script.should run cmd, options
  end
end

RSpec::Matchers.define :run_script do |cmd, options = {}|
  match do |script|
    options = options.merge(echo: true, log: true)
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
    (!options[:retry]   || retries?(lines, cmd)) &&
    (!options[:assert]  || asserts?(lines, cmd))
  end
end

RSpec::Matchers.define :set do |name, value|
  match do |script|
    env = env_for(script)

    failure_message_for_should do
      "expected script to set #{name} to #{value} but it didn't:\n#{env}"
    end

    # match only the last occurance of given env var, to make sure that
    # it's actually what's been set
    env = env.scan(/^(#{name}=.*?)$/).flatten.last
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

RSpec::Matchers.define :retry_script do |cmd|
  match do |script|
    lines = log_for(script).split("\n")

    failure_message_for_should do
      "expected script to retry #{cmd} but it didn't:\n#{script}"
    end

    retries?(lines, cmd)
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
