require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Php do
  let(:shell)  { stub('shell', :execute => true) }
  let(:config) { Travis::Build::Job::Test::Php::Config.new(:composer_args => '--dev') }
  let(:job)    { Travis::Build::Job::Test::Php.new(shell, Hashr.new(:repository => {
                                                        :slug => "owner/repo"
                                                      }), config) }

  describe 'config' do
    it 'defaults :php to "5.3"' do
      config.php.should == '5.3'
    end
  end

  describe 'setup' do
    context "when PHP version is not explicitly specified and we have to use the default one" do
      it 'switches to the default php version' do
        shell.expects(:export_line).with("TRAVIS_PHP_VERSION=5.3").returns(true)
        shell.expects(:execute).with('phpenv global 5.3').returns(true)
        shell.expects(:execute).with('php --version')

        job.setup
      end
    end

    context "when PHP version IS explicitly specified" do
      let(:config) { Travis::Build::Job::Test::Php::Config.new(:composer_args => '--dev', :php => "5.4") }

      it 'switches to the given php version' do
        shell.expects(:export_line).with("TRAVIS_PHP_VERSION=5.4").returns(true)
        shell.expects(:execute).with('phpenv global 5.4').returns(true)
        shell.expects(:execute).with('php --version')

        job.setup
      end
    end
  end

  describe 'install' do
    it 'returns "composer install --dev" if a composer file exists' do
      job.expects(:uses_composer?).returns(true)
      job.install.should == 'composer install --dev'
    end

    it 'returns nil if the composer file does not exist' do
      job.expects(:uses_composer?).returns(false)
      job.install.should be_nil
    end
  end

  describe 'script' do
    it 'returns "phpunit"' do
      job.send(:script).should == 'phpunit'
    end
  end
end


