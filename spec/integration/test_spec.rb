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
      s.execute('export FOO=foo', {}).outputs('export env')
      s.execute('export GIT_ASKPASS=echo', :echo => false)
      s.execute('git clone --depth=100 --quiet git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci').returns(true).outputs('git clone')
      s.execute('mkdir -p travis-ci/travis-ci; cd travis-ci/travis-ci', :echo => false)
      s.execute('git checkout -qf 313f61b').returns(true).outputs('git checkout')
      s.execute('rvm use 1.9.2').outputs('rvm use')
      s.execute('test -f Gemfile', :echo => false).returns(true)
      s.evaluate('pwd').returns('~/builds/travis-ci/travis-ci')
      s.execute('export BUNDLE_GEMFILE=~/builds/travis-ci/travis-ci/Gemfile', {}).outputs('export bundle gemfile')
      s.execute('bundle install', :timeout => :install).returns(true).outputs('bundle install')
      s.execute('bundle exec rake', :timeout => :script).returns(true).outputs('bundle exec rake')
    end

    runner.run

    events = observer.events
    start, finish = events.first, events.last
    start.first.should == :start

    log = observer.events[1..-2].map { |event| event.last[:output] }
    log.should == [
      'export env',
      'git clone',
      'git checkout',
      'rvm use',
      'export bundle gemfile',
      'bundle install',
      'bundle exec rake'
    ]

    finish.first.should == :finish
    finish.last.should == { :result => true }
  end
end
