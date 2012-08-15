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

  $payload = Hashr.new({
    :repository => {
      :slug => hash.repository,
      :source_url => "git://github.com/#{hash.repository}.git"
    },
    :build => {
      :commit => hash.commit,
      :id => 10
    },
    :type => 'test'
  })

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
  step 'it silently removes the ssh key'
end

Then /^it (successfully|fails to) checks? out the commit with git to the repository directory$/ do |result|
  step 'it cds into the repository directory'
  step "it #{result} checks the commit out with git"
end

Then /^it finds a file (.*) (?:and|but) (successfully|fails to) installs? dependencies with (.*)$/ do |filename, result, tool|
  step "it finds the file #{filename}"
  if tool == 'bundle'
    step 'it evaluates the current working directory'
    step "it exports the line BUNDLE_GEMFILE=~/builds/travis-ci/travis-ci/#{filename}"
  end
  step "it #{result} installs dependencies with #{tool}"
end


Then /^it exports the given environment variables$/ do
  step "it exports the line TRAVIS_PULL_REQUEST=false"
  step "it exports the line TRAVIS_SECURE_ENV_VARS=false"
  step "it exports the line TRAVIS_JOB_ID=10"

  if $payload.config.env?
    line = $payload.config.env
    step "it exports the line #{line}"
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

Then /^it exports the line (.+)$/ do |line|
  $shell.expects(:export_line).
    with(line).
    outputs("export #{line}").
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

Then /^it silently removes the ssh key/ do
  $shell.expects(:execute).
    with('rm -f ~/.ssh/source_rsa', :echo => false).
    in_sequence($sequence)
end

Then /^it (successfully|fails to) checks? the commit out with git$/ do |result|
  checkout = $shell.expects(:execute).
    with("git checkout -qf #{$payload.build.commit}").
    outputs('git checkout')

  if result == 'successfully'
    checkout.
      returns(true).
      in_sequence($sequence)

    $shell.expects(:file_exists?).
      with('.gitmodules').
      returns(false)
  else
    checkout.
      raises(Travis::AssertionFailed).
      in_sequence($sequence)
  end
end

Then /^it (successfully|fails to) switch(?:es)? to the (.*) version: (.*)$/ do |result, language, version|
  cmds = {
    'ruby'   => "rvm use #{version}",
    'erlang' => "source /home/vagrant/otp/#{version}/activate",
    'nodejs' => "nvm use #{version}",
    'php'    => "phpenv global #{version}",
    'jdk'    => "jdk_switcher use #{version}"
  }
  cmd = cmds[language.gsub('.', '')]

  options = nil
  options = { :echo => true } if language == 'ruby'

  $shell.expects(:execute).
    with(cmd, options).
    outputs(cmd).
    returns(result == 'successfully').
    in_sequence($sequence)
end

Then /it announces active (?:lein|leiningen|Leiningen) version/ do
  cmd = 'lein version'

  $shell.expects(:execute).
    with(cmd).
    outputs(cmd).
    in_sequence($sequence)
end

Then /it announces active (?:php|PHP) version/ do
  cmd = 'php --version'

  $shell.expects(:execute).
    with(cmd).
    outputs(cmd).
    in_sequence($sequence)
end

Then /it announces active (?:jdk|JDK) version/ do
  $shell.expects(:execute).
    with("java -version").
    outputs("java -version").
    in_sequence($sequence)

  $shell.expects(:execute).
    with("javac -version").
    outputs("javac -version").
    in_sequence($sequence)
end

Then /it announces active (?:ruby|Ruby) version/ do
  $shell.expects(:execute).
    with("ruby --version").
    outputs("ruby --version").
    in_sequence($sequence)

  $shell.expects(:execute).
    with("gem --version").
    outputs("gem --version").
    in_sequence($sequence)
end

Then /it announces active (?:node|node.js|Node|Node.js) version/ do
  $shell.expects(:execute).
    with("node --version").
    outputs("node --version").
    returns(true).
    in_sequence($sequence)

  $shell.expects(:execute).
    with("npm --version").
    outputs("npm --version").
    returns(true).
    in_sequence($sequence)
end

Then /^it (finds|does not find) (?:the )?file (.*)$/ do |result, filenames|
  filenames = filenames.split(/, | or /).map { |filename| filename.strip }
  filenames.each do |filename|
    $shell.expects(:file_exists?).
      with(filename).
      at_least_once.
      returns(result == 'finds').
      in_sequence($sequence)
  end
end

Then /^it (finds|does not find) directory (.*)$/ do |result, dirname|
  $shell.expects(:directory_exists?).
    with(dirname).
    at_least_once.
    returns(result == 'finds').
    in_sequence($sequence)
end

Then /^there is no local rebar in the repository$/ do
  $build.stubs(:has_local_rebar?).returns(false)
  $shell.stubs(:file_exists?).
    with("rebar").
    returns(false)
end

Then /^it evaluates the current working directory$/ do
  $shell.expects(:cwd).
    returns("~/builds/#{$payload.repository.slug}").
    in_sequence($sequence)
end

Then /^it (successfully|fails to) installs? dependencies with (.*)$/ do |result, dependencies|
  cmds = {
    'bundle'   => 'bundle install',
    'lein'     => 'lein deps',
    'maven'    => 'mvn install --quiet -DskipTests=true',
    'mvn'      => 'mvn install --quiet -DskipTests=true',
    'gradle'   => 'gradle assemble',
    'rebar'    => 'rebar get-deps',
    'npm'      => 'npm install --dev',
    'composer' => 'composer install --dev'
  }
  cmd = cmds[dependencies]

  $shell.expects(:execute).
    with(cmd, :stage => :install).
    outputs(cmd).
    returns(result == 'successfully').
    in_sequence($sequence)
end

Then /^it (successfully|fails to) runs? the (.*): (.*)$/ do |result, type, command|
  $shell.expects(:execute).
    with(command, :stage => type.to_sym).
    outputs(command).
    returns(result == 'successfully').
    in_sequence($sequence)
end

Then /^it closes the ssh session$/ do
  $shell.expects(:close).
    in_sequence($sequence)
end

Then /^it returns the result (.*)$/ do |result|
  $build.run[:result].should == result.to_i
end

Then /^it has captured the following events$/ do |table|
  expected = table.hashes.map { |hash| Hashr.new(hash) }
  actual = $observer.events

  expected.each_with_index do |expected, ix|
    actual[ix][0].should == expected.name

    decode(expected.data).each do |key, value|
      case value
      when Regexp
        actual[ix][1][key].should =~ value
      else
        actual[ix][1][key].should == value
      end
    end
  end
end
