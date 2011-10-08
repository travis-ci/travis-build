require 'spec_helper'
require 'support/mocks'
require 'support/payloads'
require 'support/helpers'

# TODO add runner specs, check observers

describe Factory do
  let(:vm)         { stub('vm') }
  let(:session)    { Mocks::SshSession.new }
  let(:http)       { stub('http') }
  let(:runner)     { Factory.new(vm, session, http, payload).runner }
  let(:job)        { runner.job }
  let(:commit)     { job.commit }
  let(:repository) { job.commit.repository }
  let(:scm)        { job.commit.repository.scm }

  shared_examples_for 'a github commit' do
    it 'has a github repository' do
      commit.repository.should be_a(Repository::Github)
    end

    it 'has the hash from the payload' do
      commit.hash.should == payload['build']['commit']
    end

    describe 'the repository' do
      it 'has an git scm' do
        repository.scm.should be_a(Scm::Git)
      end

      it 'has the slug from the payload' do
        repository.slug.should == payload['repository']['slug']
      end
    end

    describe 'the scm' do
      it 'has a shell' do
        scm.shell.should be_a(Shell)
      end
    end

    describe 'the shell' do
      it 'has the ssh session' do
        scm.shell.session.should == session
      end
    end
  end

  describe 'with a configure payload' do
    let(:payload) { deep_clone(PAYLOADS[:configure]) }

    it 'uses a Job::Runner instance' do
      runner.should be_a(Job::Runner)
    end

    it 'uses a Job::Configure instance' do
      job.should be_a(Job::Configure)
    end

    describe 'the configure job' do
      it 'has the given http connection' do
        job.http.should == http
      end

      it 'has a commit' do
        job.commit.should be_a(Commit)
      end
    end

    describe 'the commit' do
      it_behaves_like 'a github commit'
    end
  end

  describe 'with a test payload' do
    let(:payload) { deep_clone(PAYLOADS[:test]) }

    it 'uses a Job::Runner::Remote instance' do
      runner.should be_a(Job::Runner)
    end

    describe 'with no language given' do
      it 'uses a Job::Test::Ruby instance' do
        job.should be_a(Job::Test::Ruby)
      end

      it 'uses a Job::Test::Ruby::Config instance' do
        job.config.should be_a(Job::Test::Ruby::Config)
      end
    end

    describe 'with "erlang" given as a language' do
      before :each do
        payload['config']['language'] = 'erlang'
      end

      it 'uses a Job::Test::Erlang instance' do
        job.should be_a(Job::Test::Erlang)
      end

      it 'uses a Job::Test::Erlang::Config instance' do
        job.config.should be_a(Job::Test::Erlang::Config)
      end
    end

    describe 'the test job' do
      it 'has a shell' do
        job.shell.should be_a(Shell)
      end

      it 'has a commit' do
        job.commit.should be_a(Commit)
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
