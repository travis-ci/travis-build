require 'spec_helper'

describe Travis::Shell::Generator::Bash::Cmd, :include_node_helpers do
  let(:args)    { ['cd ..', @options || {}] }
  let(:subject) { Travis::Shell::Generator::Bash::Cmd.new(*args).to_bash }

  it 'prefixes with `travis_cmd` and escapes the code' do
    should eql('travis_cmd cd\ ..')
  end

  it 'adds sudo if :sudo is given' do
    @options = { sudo: true }
    should eql('travis_cmd sudo\ cd\ ..')
  end

  it 'adds --assert if :assert is given' do
    @options = { assert: true }
    should eql('travis_cmd cd\ .. --assert')
  end

  it 'adds --echo if :echo is given' do
    @options = { echo: true }
    should eql('travis_cmd cd\ .. --echo')
  end

  it 'adds both --echo and --display if :echo is a String' do
    @options = { echo: 'display' }
    should eql('travis_cmd cd\ .. --echo --display display')
  end

  it 'adds --retry if :retry is given' do
    @options = { retry: true }
    should eql('travis_cmd cd\ .. --retry')
  end

  it 'adds --timing if :timing is given' do
    @options = { timing: true }
    should eql('travis_cmd cd\ .. --timing')
  end
end
