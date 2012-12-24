def runs?(lines, cmd)
  cmd = /^#{Regexp.escape(cmd)}/ if cmd.is_a?(String)
  lines.detect { |line| line =~ cmd }
end

def echoes?(lines, cmd)
  runs? lines, "echo $ #{cmd}"
end

def logs?(lines, cmd)
  cmd = /^output from #{Regexp.escape(cmd)}/
  lines = File.read('tmp/build.log').split("\n")
  lines.detect { |line| line =~ cmd }
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
  system script unless File.exists?('tmp/test.log')
  File.read('tmp/test.log')
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
    failure_message_for_should do
      "expected script to set #{name} to #{value} but it didn't:\n#{script}"
    end

    script.include?("#{name}=#{value}")
  end
end
