require 'spec_helper'

describe Travis::Build::Script::Scala do
  let(:config) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(config).compile }

  it_behaves_like 'a build script'
  # it_behaves_like 'a jdk build'

  it 'sets TRAVIS_SCALA_VERSION' do
    should set 'TRAVIS_SCALA_VERSION', '2.9.2'
  end

  it 'announces Scala 2.9.2' do
    should run 'echo Using Scala 2.9.2'
  end

  it 'runs sbt ++2.9.2 test if ./project exists' do
    file('project')
    should run 'sbt ++2.9.2 test', echo: true, log: true, timeout: timeout_for(:script)
  end

  it 'runs sbt ++2.9.2 test if ./build.sbt exists' do
    file('build.sbt')
    should run 'sbt ++2.9.2 test', echo: true, log: true, timeout: timeout_for(:script)
  end

  it 'runs mvn test no project or build file exists' do
    should run 'mvn test', echo: true, log: true, timeout: timeout_for(:script)
  end
end
