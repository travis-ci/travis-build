require 'spec_helper'
require 'timeout'

require_relative '../public/filter/redirect_io'

describe Filter do
  let(:cmd) { File.expand_path('../../public/filter/redirect_io.rb', __FILE__) }
  def filter(input, *secrets)
    args  = secrets.map { |s| "-s #{Shellwords.escape(s)}" }.join " "
    input = Shellwords.escape(input)
    `echo #{input} | ruby #{cmd} #{args}`.chomp
  end

  describe 'simple replacements' do
    example { expect(filter('foobar', 'baz')).to be == 'foobar' }
    example { expect(filter('foobar foobaz', 'foobar', 'baz')).to be == '[secure] foo[secure]' }
    example { expect(filter('foobar foobaz', 'foobar', 'foo')).to be == '[secure] [secure]baz' }
    example { expect(filter('foobar foobaz', 'foo', 'foobar')).to be == '[secure] [secure]baz' }
    example { expect(filter('abcdef', 'a', 'bc', 'def')).to be == 'abc[secure]' }
  end

  it 'live streams' do
    code = %(
      print 'foo'
      sleep 0.01
      print 'bar'
      sleep 0.01
      print 'baz'
      sleep 0.01
    )
    output = `ruby -e "#{code}" | ruby #{cmd} -s bar`
    expect(output).to be == 'foo[secure]baz'
  end
end
