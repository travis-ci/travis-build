require 'spec_helper'
require 'support/payloads'
require 'support/mocks'

describe 'Integration', Job::Test do
  let(:vm)       { Mocks::Vm.new }
  let(:session)  { Mocks::SshSession.new({ :host => '127.0.0.1', :port => 2220}) }
  let(:observer) { Mocks::Observer.new }
  let(:runner)   { Job.runner(vm, session, {}, payload, [observer]) }
  let(:payload)  { PAYLOADS[:test] }

  it 'works' do
    session.expect do |s|
      s.execute('mkdir -p ~/builds; cd ~/builds', :echo => false)
      s.execute('export FOO=foo', {})
      s.execute('export GIT_ASKPASS=echo', :echo => false)
      s.execute('git clone --depth=100 --quiet git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci').returns(true)
      s.execute('mkdir -p travis-ci/travis-ci; cd travis-ci/travis-ci', :echo => false)
      s.execute('git checkout -qf 313f61b').returns(true)
      s.execute('rvm use 1.9.2')
      s.execute('test -f Gemfile', :echo => false).returns(true)
      s.evaluate('pwd').returns('~/builds/travis-ci/travis-ci')
      s.execute('export BUNDLE_GEMFILE=~/builds/travis-ci/travis-ci/Gemfile', {})
      s.execute('bundle install', :timeout => :install).returns(true)
      s.execute('bundle exec rake', :timeout => :script).returns(true)
    end

    runner.run

    start, finish = *observer.events
    start.first.should == :start

    # TODO add a way to simulate ssh output, too

    finish.first.should == :finish
    finish.last.should == { :result => true }
  end
end
