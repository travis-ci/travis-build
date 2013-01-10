require 'spec_helper'

describe Travis::Build::Script::Scala do
  let(:options) { { logs: { build: true, state: true } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

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
    should run_script 'sbt ++2.9.2 test'
  end

  it 'runs sbt ++2.9.2 test if ./build.sbt exists' do
    file('build.sbt')
    should run_script 'sbt ++2.9.2 test'
  end

  it 'runs mvn test no project or build file exists' do
    should run_script 'mvn test'
  end
end
