require 'hashr'
require 'active_support/core_ext/hash/keys'

def decode(string)
  string.split(',').inject({}) do |result, pair|
    key, value = pair.split(':').map { |token| token.strip }

    value = case value
    when '[now]'
      Time.now
    when 'true', 'false'
      eval(value)
    when /^\/.*\/$/
      eval(value)
    else
      value
    end

    result.merge(key => value)
  end.symbolize_keys
end

Given /^the following test payload$/ do |table|
  hash = Hashr.new(table.rows_hash)

  $payload = Hashr.new(
    :repository => { :slug => hash.repository },
    :build      => { :commit => hash.commit }
  )
  $payload.config = decode(hash.config) if hash.config?
end

When /^it starts a job$/ do
  $vm       = Mocks::Vm.new
  $session  = Mocks::SshSession.new
  $http     = stub('http')
  $observer = Mocks::Observer.new
  $sequence = sequence('build')
  $runner   = Travis::Build::Job.runner($vm, $session, $http, $payload, [$observer])

  And 'it opens the ssh session'
  And 'it cds into the builds dir'
end

Then /^it (successfully|fails to) clones? the repository to the build dir with git$/ do |result|
  And 'it silently disables interactive git auth'
  And "it #{result} clones the repository with git"
end

Then /^it (successfully|fails to) checks? out the commit with git to the repository directory$/ do |result|
  And 'it cds into the repository directory'
  And "it #{result} checks the commit out with git"
end

Then /^it finds a file (.*) (?:and|but) (successfully|fails to) installs? the (.*)$/ do |filename, result, dependencies|
  And "it finds the file #{filename}"
  if dependencies == 'bundle'
    And 'it evaluates the current working directory'
    And "it exports BUNDLE_GEMFILE=~/builds/travis-ci/travis-ci/#{filename}"
  end
  And "it #{result} installs the #{dependencies}"
end


Then /^it exports the given environment variables$/ do
  if $payload.config.env?
    name, value = $payload.config.env.split('=')
    And "it exports #{name}=#{value}"
  end
end

Then /^it opens the ssh session$/ do
  $session.expects(:connect).
           in_sequence($sequence)
end

Then /^it cds into the (.*)$/ do |dir|
  dirs = {
    'builds dir' => '~/builds',
    'repository directory' => $payload.repository.slug
  }
  dir = dirs[dir]

  $session.expects(:execute).
           with("mkdir -p #{dir}", :echo => false).
           in_sequence($sequence)

  $session.expects(:execute).
           with("cd #{dir}").
           outputs("cd #{dir}").
           in_sequence($sequence)
end

Then /^it exports (.*)=(.*)$/ do |name, value|
  $session.expects(:execute).
           with("export #{name}=#{value}").
           outputs("export #{name}").
           in_sequence($sequence)
end

Then /^it silently disables interactive git auth$/ do
  $session.expects(:execute).
           with('export GIT_ASKPASS=echo', :echo => false).
           in_sequence($sequence)
end

Then /^it (successfully|fails to) clones? the repository with git$/ do |result|
  $session.expects(:execute).
           with("git clone --depth=100 --quiet git://github.com/#{$payload.repository.slug}.git #{$payload.repository.slug}").
           outputs('git clone').
           returns(result == 'successfully').
           in_sequence($sequence)
end

Then /^it (successfully|fails to) checks? the commit out with git$/ do |result|
  $session.expects(:execute).
           with("git checkout -qf #{$payload.build.commit}").
           outputs('git checkout').
           returns(result == 'successfully').
           in_sequence($sequence)
end

Then /^it (successfully|fails to) switch(?:es)? to the (.*) version: (.*)$/ do |result, language, version|
  cmds = {
    'ruby'   => "rvm use #{version}",
    'erlang' => "source /home/vagrant/otp/#{version}/activate",
    'nodejs' => "nvm use v#{version}"
  }
  cmd = cmds[language.gsub('.', '')]

  if language == 'ruby'
    $session.expects(:execute).
             with(cmd).
             outputs(cmd).
             in_sequence($sequence)
    $session.expects(:evaluate).
             with('rvm current').
             returns(result == 'successfully' ? version : 'something else').
             in_sequence($sequence)
  else
    $session.expects(:execute).
             with(cmd).
             outputs(cmd).
             returns(result == 'successfully').
             in_sequence($sequence)
  end
end

Then /^it (finds|does not find) the file (.*)$/ do |result, filenames|
  filenames = filenames.split(/, | or /).map { |filename| filename.strip }
  filenames.each do |filename|
    $session.expects(:execute).
             with("test -f #{filename}", :echo => false).
             returns(result == 'finds').
             in_sequence($sequence)
  end
end

Then /^it evaluates the current working directory$/ do
  $session.expects(:evaluate).
           with('pwd').
           returns("~/builds/#{$payload.repository.slug}").
           in_sequence($sequence)
end

Then /^it (successfully|fails to) installs? the (.*)$/ do |result, dependencies|
  cmds = {
    'bundle' => 'bundle install',
    'lein dependencies' => 'lein deps',
    'rebar dependencies' => './rebar get-deps',
    'npm packages' => 'npm install --dev'
  }
  cmd = cmds[dependencies]

  $session.expects(:execute).
           with(cmd, :timeout => :install).
           outputs(cmd).
           returns(result == 'successfully').
           in_sequence($sequence)
end

Then /^it (successfully|fails to) runs? the (.*): (.*)$/ do |result, type, command|
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

Then /^it has captured the following events$/ do |table|
  expected = table.hashes.map { |hash| Hashr.new(hash) }
  actual = $observer.events

  expected.each_with_index do |expected, ix|
    actual[ix].name.should == expected.name

    decode(expected.data).each do |key, value|
      case value
      when Regexp
        actual[ix].data[key].should =~ value
      else
        actual[ix].data[key].should == value
      end
    end
  end
end
