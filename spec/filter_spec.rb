require 'spec_helper'
require 'timeout'

require_relative '../public/filter'

describe Filter do
  class CustomWriter < Filter::Scanner
    def read(&block)
      reader.each_char(&block)
    end
  end

  def filter(input, *secrets)
    io     = StringIO.new
    filter = secrets.inject(CustomWriter.new(input)) { |r, s| Filter::StringFilter.new(r, s) }
    filter.run(io)
    io.string
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
    expect(with_timeout(command, 0.5)).to be == 'foobar'
  end
end
