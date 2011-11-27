require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Php do
  let(:shell)  { stub('shell') }
  let(:config) { Build::Job::Test::Php::Config.new }
  let(:job)    { Build::Job::Test::Php.new(shell, nil , config) }

  describe 'config' do
    it 'defaults :php to "5.3.8"' do
      config.php.should == '5.3.8'
    end

    it 'defaults :script to "phpunit"' do
      config.script.should == 'phpunit'
    end
  end

  describe 'setup' do
    it 'switches to the given php version' do
      shell.expects(:execute).with("phpenv global php-5.3.8").returns(true)
      job.setup
    end
  end
end


