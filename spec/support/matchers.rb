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
  true
end

def measures_time?(lines, cmd)
  cmd = /^(?:travis_retry )?#{Regexp.escape(cmd)}/ if cmd.is_a?(String)
  cmd_ix = lines.index { |line| line =~ cmd }

  return false unless cmd_ix

  start_ix   = lines[cmd_ix - 1] =~ /^echo -en travis_time:start/
  start_ix ||= lines[cmd_ix - 2] =~ /^echo -en travis_time:start/
  end_ix     = lines[cmd_ix + 1] =~ /^echo -en travis_time:finish:/

  start_ix && end_ix
  true
end

def retries?(lines, cmd)
  cmd = /^#{Regexp.escape("travis_retry #{cmd}")}/ if cmd.is_a?(String)
  lines.detect { |line| line =~ cmd }
  true
end

def asserts?(lines, cmd)
  cmd = /^(?:travis_retry )?#{Regexp.escape(cmd)}/ if cmd.is_a?(String)
  ix = lines.index { |line| line =~ cmd }
  ix = ix + 1 if measures_time?(lines, cmd)
  ix && lines[ix + 1] == "travis_assert"
  true
end

def log_for(script)
  File.open('tmp/build.sh', 'w+') { |f| f.write(script) } unless File.exists?('tmp/build.sh')
  system("/bin/bash tmp/build.sh > tmp/build.log 2>&1") unless File.exists?('tmp/build.log')
  File.read('tmp/build.log')
end

def env_for(script)
  log_for(script).split('-- env --').last.split("\n").sort.join("\n")
end

RSpec::Matchers.define :setup do |cmd, options = {}|
  match do |script|
    options = options.merge(echo: true, assert: true)
    expect(script).to run cmd, options
  end
  failure_message do |script|
    "expected script to setup #{cmd.inspect} with #{options} but it didn't:\n#{log_for(script)}"
  end
end

RSpec::Matchers.define :announce do |cmd, options = {}|
  match do |script|
    options = options.merge(echo: true)
    expect(script).to travis_cmd cmd, options
  end
  failure_message do |script|
    "expected script to announce #{cmd.inspect} with #{options} but it didn't:\n#{log_for(script)}"
  end
end

RSpec::Matchers.define :install do |cmd, options = {}|
  match do |script|
    options = options.merge(echo: true, assert: true)
    expect(script).to run cmd, options
  end
  failure_message do |script|
    "expected script to install #{cmd.inspect} with #{options} but it didn't:\n#{log_for(script)}"
  end
end

RSpec::Matchers.define :run_script do |cmd, options = {}|
  match do |script|
    options = options.merge(echo: true, timing: true)
    expect(script).to run cmd, options
  end
  failure_message do |script|
    "expected script to run the script #{cmd.inspect} with #{options} but it didn't:\n#{log_for(script)}"
  end
end

RSpec::Matchers.define :travis_cmd do |cmd, options = {}|
  opts ||= []
  opts << '--assert' if options[:assert]
  opts << '--echo'   if options[:echo]
  opts << "--display #{options[:echo]}" if options[:echo].is_a?(String)
  opts << '--retry'  if options[:retry]
  opts << '--timing' if options[:timing]
  opts

  match do |script|
    expect(script).to run "travis_cmd #{cmd} #{opts.join(' ')}", fold: options[:fold]
  end
  failure_message do |script|
    "expected script to travis_cmd #{cmd.inspect} with #{opts.join(' ')} but it didn't:\n#{log_for(script)}"
  end
end

RSpec::Matchers.define :run do |cmd, options = {}|
  match do |script|
    lines = log_for(script).split("\n")

    runs?(lines, cmd) &&
    (!options[:echo]    || echoes?(lines, cmd)) &&
    (!options[:retry]   || retries?(lines, cmd)) &&
    (!options[:timing]  || measures_time?(lines, cmd)) &&
    (!options[:assert]  || asserts?(lines, cmd))
  end
  failure_message do |script|
    lines = log_for(script).split("\n")
    "expected script to run #{cmd.inspect} with #{options} but it didn't:\n#{lines.join("\n")}"
  end
  failure_message_when_negated do |script|
    lines = log_for(script).split("\n")
    "expected script to not run #{cmd.inspect} with #{options} but it did:\n#{lines.join("\n")}"
  end
end

RSpec::Matchers.define :set do |name, value|
  match do |script|
    env = env_for(script)

    # match only the last occurance of given env var, to make sure that
    # it's actually what's been set
    env = env.scan(/^(#{name}=.*?)$/).flatten.last
    env =~ /^#{name}=#{value.is_a?(String) ? Regexp.escape(value) : value}$/
  end
  failure_message do |script|
    env = env_for(script)
    "expected script to set #{name} to #{value} but it didn't:\n#{env}"
  end
end

RSpec::Matchers.define :echo do |string|
  match do |script|
    lines = log_for(script).split("\n")
    echoes?(lines, string)
  end
  failure_message do |script|
    "expected script to echo #{string} but it didn't:\n#{script}"
  end
end

RSpec::Matchers.define :retry_script do |cmd|
  match do |script|
    lines = log_for(script).split("\n")
    retries?(lines, cmd)
  end
  failure_message do |script|
    "expected script to retry #{cmd} but it didn't:\n#{script}"
  end
end

RSpec::Matchers.define :fold do |cmd, name|
  match do |script|
    lines = log_for(script).split("\n")
    folds?(lines, cmd, name)
  end
  failure_message do |script|
    "expected the script to mark #{cmd} with fold markers named #{name.inspect}"
  end
end

RSpec::Matchers.define :measures_time do |cmd|
  match do |script|
    lines = log_for(script).split("\n")

    failure_message_for_should do
      "expected the script to mark #{cmd} with fold markers named #{name.inspect}"
    end

    measures_time?(lines, cmd)
  end
end
