require 'spec_helper'
require 'timeout'

require_relative '../public/filter'

describe Filter do
  def filter(input, *secrets)
    path = File.expand_path('../../public/filter.rb', __FILE__)
    secrets = secrets.map { |s| "-s #{Shellwords.escape(s)}" }.join " "
    `ruby #{path} echo\\ #{Shellwords.escape(input)} #{secrets}`.chomp
  end

  def with_timeout(command, timeout)
    output = ""
    Timeout.timeout(timeout) { Filter::Runner.new(command).read { |c| output << c} }
    output
  rescue Timeout::Error
    output
  end

  describe 'simple replacements' do
    example { expect(filter('foobar', 'baz')).to be == 'foobar' }
    example { expect(filter('foobar foobaz', 'foobar', 'baz')).to be == '[secure] foo[secure]' }
    example { expect(filter('foobar foobaz', 'foobar', 'foo')).to be == '[secure] [secure]baz' }
    example { expect(filter('foobar foobaz', 'foo', 'foobar')).to be == '[secure] [secure]baz' }
  end

  it 'live streams' do
    command = %q[ruby public/filter.rb 'ruby -e "print :foo; sleep 0.01; print :bar; sleep"']
    expect(with_timeout(command, 1)).to be == 'foobar'
  end
end
