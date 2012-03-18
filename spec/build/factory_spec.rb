require 'spec_helper'
require 'spec_helper/mocks'
require 'spec_helper/payloads'
require 'spec_helper/helpers'
require 'travis/build'

# TODO check observers

describe Travis::Build::Factory do
  let(:vm)         { stub('vm', :name => 'worker-1') }
  let(:shell)      { stub('shell') }
  let(:observer)   { stub('observer') }
  let(:config)     { {} }

  let(:build)      { Travis::Build.create(vm, shell, [observer], payload, config) }

  let(:job)        { build.job }
  let(:commit)     { build.job.commit }
  let(:repository) { build.job.commit.repository }
  let(:scm)        { build.job.commit.repository.scm }

  shared_examples_for 'a github commit' do
    it 'has a github repository' do
      commit.repository.should be_a(Travis::Build::Repository::Github)
    end

    it 'has the sha reference from the payload' do
      commit.ref.should == payload['build']['commit']
    end

    describe 'the repository' do
      it 'has an git scm' do
        repository.scm.should be_a(Travis::Build::Scm::Git)
      end

      it 'has the slug from the payload' do
        repository.slug.should == payload['repository']['slug']
      end
    end

    describe 'the scm' do
      it 'has a shell' do
        scm.shell.should == shell
      end
    end
  end

  describe 'with a configure payload' do
    let(:payload) { deep_clone(PAYLOADS[:configure]) }

    it 'uses a Job::Runner instance' do
      build.should be_a(Travis::Build)
    end

    it 'uses a Job::Configure instance' do
      job.should be_a(Travis::Build::Job::Configure)
    end

    describe 'the configure job' do
      it 'has the given http connection' do
        job.http.should be_a(Travis::Build::Connection::Http)
      end

      it 'has a commit' do
        job.commit.should be_a(Travis::Build::Commit)
      end
    end

    describe 'the commit' do
      it_behaves_like 'a github commit'
    end
  end

  describe 'with a test payload' do
    let(:payload) { deep_clone(PAYLOADS[:test]) }

    it 'uses a Build::Remote instance' do
      build.should be_a(Travis::Build::Remote)
    end

    describe 'with no language given' do
      it 'uses a Job::Test::Ruby instance' do
        job.should be_a(Travis::Build::Job::Test::Ruby)
      end

      it 'uses a Job::Test::Ruby::Config instance' do
        job.config.should be_a(Travis::Build::Job::Test::Ruby::Config)
      end
    end

    describe 'with "erlang" given as a language' do
      before :each do
        payload['config']['language'] = 'erlang'
      end

      it 'uses a Job::Test::Erlang instance' do
        job.should be_a(Travis::Build::Job::Test::Erlang)
      end

      it 'uses a Job::Test::Erlang::Config instance' do
        job.config.should be_a(Travis::Build::Job::Test::Erlang::Config)
      end
    end

    describe 'with "PHP" given as a language' do
      before :each do
        payload['config']['language'] = 'PHP'
      end

      it 'uses a Job::Test::Php instance' do
        job.should be_a(Travis::Build::Job::Test::Php)
      end

      it 'uses a Job::Test::Php::Config instance' do
        job.config.should be_a(Travis::Build::Job::Test::Php::Config)
      end
    end

    describe 'with an array of known languages given as a language' do
      before :each do
        payload['config']['language'] = ['php', 'erlang']
      end

      it 'uses the first lanaguge and returns a Job::Test::Php instance' do
        job.should be_a(Travis::Build::Job::Test::Php)
      end
    end

    describe 'with an array of unknown languages given as a language' do
      before :each do
        payload['config']['language'] = ['fraggle', 'rock']
      end

      it 'uses a Job::Test::Ruby::Config instance' do
        job.should be_a(Travis::Build::Job::Test::Ruby)
      end
    end

    describe 'the test job' do
      it 'has a shell' do
        job.shell.should == shell
      end

      it 'has a commit' do
        job.commit.should == commit
      end

      it 'has the test config from the payload' do
        job.config.should == { :rvm => '1.9.2', :gemfile => 'Gemfile', :env => 'FOO=foo' }
      end
    end

    describe 'the commit' do
      it_behaves_like 'a github commit'
    end

    describe 'the shell' do
      it 'is used on the job and the scm' do
        job.shell.should equal(scm.shell)
      end
    end
  end
end
