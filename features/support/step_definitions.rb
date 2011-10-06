When /^a ruby payload comes in and starts a test job$/ do
  $vm       = Mocks::Vm.new
  $session  = Mocks::SshSession.new(:host => '127.0.0.1', :port => 2220)
  $payload  = PAYLOADS[:test]
  $observer = Mocks::Observer.new
  $sequence = sequence('build')
  $runner   = Travis::Build::Job.runner($vm, $session, {}, $payload, [$observer])

  And 'it opens the ssh session'
  And 'it cds into the builds dir'
  And 'it exports the given environment variables'
end

When /^it (successfully|fails to) clones? the repository to the build dir with git$/ do |result|
  And 'it silently disables interactive git auth'
  And "it #{result} clones the repository with git"
end

When /^it (successfully|fails to) checks? out the commit with git to the repository directory$/ do |result|
  And 'it cds into the repository directory'
  And "it #{result} checks the commit out with git"
end

When /^it finds the Gemfile and (successfully|fails to) installs? the bundle$/ do |result|
  And 'it finds the following file exists: Gemfile'
  And 'it evaluates the current working directory'
  And 'it exports BUNDLE_GEMFILE=~/builds/travis-ci/travis-ci/Gemfile'
  And "it #{result} installs the bundle"
end


When /^it opens the ssh session$/ do
  $session.expects(:connect).
           in_sequence($sequence)
end

When /^it cds into the builds dir$/ do
  $session.expects(:execute).
           with('mkdir -p ~/builds; cd ~/builds', :echo => false).
           in_sequence($sequence)
end

When /^it exports the given environment variables$/ do
  And "it exports FOO=foo"
end

When /^it exports (.*)=(.*)$/ do |name, value|
  $session.expects(:execute).
           with("export #{name}=#{value}").
           outputs("export #{name}=#{value}").
           in_sequence($sequence)
end

When /^it silently disables interactive git auth$/ do
  $session.expects(:execute).
           with('export GIT_ASKPASS=echo', :echo => false).
           in_sequence($sequence)
end

When /^it (successfully|fails to) clones? the repository with git$/ do |result|
  $session.expects(:execute).
           with('git clone --depth=100 --quiet git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci').
           outputs('git clone').
           returns(result == 'successfully').
           in_sequence($sequence)
end

When /^it cds into the repository directory$/ do
  $session.expects(:execute).
           with('mkdir -p travis-ci/travis-ci; cd travis-ci/travis-ci', :echo => false).
           in_sequence($sequence)
end

When /^it (successfully|fails to) checks? the commit out with git$/ do |result|
  $session.expects(:execute).
           with('git checkout -qf 313f61b').
           outputs('git checkout -qf 313f61b').
           returns(result == 'successfully').
           in_sequence($sequence)
end

When /^it (successfully|fails to) switch(?:es)? to the ruby version: (.*)$/ do |result, version|
  $session.expects(:execute).
           with("rvm use #{version}").
           outputs("rvm use #{version}").
           in_sequence($sequence)
end

When /^it finds the following file (exists|does not exist): (.*)$/ do |result, filename|
  $session.expects(:execute).
           with("test -f #{filename}", :echo => false).
           returns(result == 'exists').
           in_sequence($sequence)
end

When /^it evaluates the current working directory$/ do
  $session.expects(:evaluate).
           with('pwd').
           returns('~/builds/travis-ci/travis-ci').
           in_sequence($sequence)
end

When /^it (successfully|fails to) installs? the bundle$/ do |result|
  $session.expects(:execute).
           with('bundle install', :timeout => :install).
           outputs('bundle install').
           returns(result == 'successfully').
           in_sequence($sequence)
end

When /^it (successfully|fails to) runs? the (.*): (.*)$/ do |result, type, command|
  $session.expects(:execute).
           with(command, :timeout => type.to_sym).
           outputs(command).
           returns(result == 'successfully').
           in_sequence($sequence)
end

Then /^it closes the ssh session$/ do
  $session.expects(:close).
           in_sequence($sequence)
end

Then /^it returns (.*)$/ do |result|
  $runner.run.should == eval(result)
end


