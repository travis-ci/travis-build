require 'spec_helper'

describe Build::Job::Test::Php do
  let(:shell)  { stub('shell') }
  let(:config) { Build::Job::Test::Php::Config.new }
  let(:job)    { Build::Job::Test::Php.new(shell, nil , config) }

  describe 'config defaults' do
    it ':php to "5.3.8"' do
      config.php.should == '5.3.8'
    end
  end

  describe 'setup' do
    it 'switches to the given php version' do
      shell.expects(:execute).with("phpenv global php-5.3.8").returns(true)
      job.setup
    end
  end

  describe 'script' do
    it 'prefers the script from the config' do
      config.script = 'custom'
      job.send(:script).should == 'custom'
    end

    it 'defaults to "phpunit"' do
      job.send(:script).should == 'phpunit'
    end
  end
end


