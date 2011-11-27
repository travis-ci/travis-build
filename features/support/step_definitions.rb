require 'hashr'
require 'active_support/core_ext/hash/keys'

def decode(string)
  string.split(',').inject({}) do |result, pair|
    key, value = pair.split(':').map { |token| token.strip }

    value = case value
    when '[now]'
      Time.now.utc
    when 'true', 'false'
      eval(value)
    when /^\/.*\/$/
      eval(value)
    when /^\d*$/
      value.to_i
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
  $shell    = Mocks::Shell.new
  $observer = Mocks::Observer.new
  $sequence = sequence('build')
  $build    = Travis::Build.create($vm, $shell, [$observer], $payload, {})

  step 'it opens the ssh session'
  step 'it cds into the builds dir'
end

Then /^it (successfully|fails to) clones? the repository to the build dir with git$/ do |result|
  step 'it silently disables interactive git auth'
  step "it #{result} clones the repository with git"
end

Then /^it (successfully|fails to) checks? out the commit with git to the repository directory$/ do |result|
  step 'it cds into the repository directory'
  step "it #{result} checks the commit out with git"
end

Then /^it finds a file (.*) (?:and|but) (successfully|fails to) installs? the (.*)$/ do |filename, result, dependencies|
  step "it finds the file #{filename}"
  if dependencies == 'bundle'
    step 'it evaluates the current working directory'
    step "it exports BUNDLE_GEMFILE=~/builds/travis-ci/travis-ci/#{filename}"
  end
  step "it #{result} installs the #{dependencies}"
end


Then /^it exports the given environment variables$/ do
  if $payload.config.env?
    name, value = $payload.config.env.split('=')
    step "it exports #{name}=#{value}"
  end
end

Then /^it opens the ssh session$/ do
  $shell.expects(:connect).
           in_sequence($sequence)
end

Then /^it cds into the (.*)$/ do |dir|
  dirs = {
    'builds dir' => '~/builds',
    'repository directory' => $payload.repository.slug
  }
  dir = dirs[dir]

  $shell.expects(:chdir).
           with(dir).
           outputs("cd #{dir}").
           in_sequence($sequence)
end

Then /^it exports (.*)=(.*)$/ do |name, value|
  $shell.expects(:export).
           with(name, value).
           outputs("export #{name}").
           in_sequence($sequence)
end

Then /^it silently disables interactive git auth$/ do
  $shell.expects(:export).
           with('GIT_ASKPASS', 'echo', :echo => false).
           in_sequence($sequence)
end

Then /^it (successfully|fails to) clones? the repository with git$/ do |result|
  $shell.expects(:execute).
           with("git clone --depth=100 --quiet git://github.com/#{$payload.repository.slug}.git #{$payload.repository.slug}").
           outputs('git clone').
           returns(result == 'successfully').
           in_sequence($sequence)
end

Then /^it (successfully|fails to) checks? the commit out with git$/ do |result|
  $shell.expects(:execute).
           with("git checkout -qf #{$payload.build.commit}").
           outputs('git checkout').
           returns(result == 'successfully').
           in_sequence($sequence)
end

Then /^it (successfully|fails to) switch(?:es)? to the (.*) version: (.*)$/ do |result, language, version|
  cmds = {
    'ruby'   => "rvm use #{version}",
    'erlang' => "source /home/vagrant/otp/#{version}/activate",
    'nodejs' => "nvm use #{version}",
    'php'    => "phpenv global php-#{version}"
  }
  cmd = cmds[language.gsub('.', '')]

  if language == 'ruby'
    $shell.expects(:evaluate).
             with(cmd, :echo => true).
             outputs(cmd).
             returns(result == 'successfully' ? "Using #{version}" : "WARN: #{version} is not installed").
             in_sequence($sequence)
  else
    $shell.expects(:execute).
             with(cmd).
             outputs(cmd).
             returns(result == 'successfully').
             in_sequence($sequence)
  end
end

Then /^it (finds|does not find) the file (.*)$/ do |result, filenames|
  filenames = filenames.split(/, | or /).map { |filename| filename.strip }
  filenames.each do |filename|
    $shell.expects(:file_exists?).
             with(filename).
             returns(result == 'finds').
             in_sequence($sequence)
  end
end

Then /^it evaluates the current working directory$/ do
  $shell.expects(:cwd).
           returns("~/builds/#{$payload.repository.slug}").
           in_sequence($sequence)
end

Then /^it (successfully|fails to) installs? the (.*)$/ do |result, dependencies|
  cmds = {
    'bundle' => 'bundle install',
    'lein dependencies' => 'lein deps',
    'rebar dependencies' => './rebar get-deps',
    'npm packages' => 'npm install --dev',
    'composer packages' => 'composer install --dev'
  }
  cmd = cmds[dependencies]

  $shell.expects(:execute).
           with(cmd, :timeout => :install).
           outputs(cmd).
           returns(result == 'successfully').
           in_sequence($sequence)
end

Then /^it (successfully|fails to) runs? the (.*): (.*)$/ do |result, type, command|
  $shell.expects(:execute).
           with(command, :timeout => type.to_sym).
           outputs(command).
           returns(result == 'successfully').
           in_sequence($sequence)
end

Then /^it closes the ssh session$/ do
  $shell.expects(:close).
           in_sequence($sequence)
end

Then /^it returns the status (.*)$/ do |result|
  $build.run[:status].should == result.to_i
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
