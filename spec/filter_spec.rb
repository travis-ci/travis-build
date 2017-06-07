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
    example { expect(filter('abcdef', 'a', 'bc', 'def')).to be == 'abc[secure]' }
  end

  describe 'sets the status code correctly' do
    example do
      with_timeout('true', 1)
      expect($?.exitstatus).to be == 0
    end

    example do
      with_timeout('false', 1)
      expect($?.exitstatus).to be == 1
    end

    example do
      with_timeout('sleep 0.2; exit 128', 1)
      expect($?.exitstatus).to be == 128
    end
  end

  it 'live streams' do
    command = %q[ruby public/filter.rb 'ruby -e "print :foo; sleep 0.01; print :bar; sleep"']
    expect(with_timeout(command, 2)).to be == 'foobar'
  end
end
