require 'spec_helper'

describe Travis::Build::Script::Scala do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'
  it_behaves_like 'a jvm build'

  it 'sets TRAVIS_SCALA_VERSION' do
    should set 'TRAVIS_SCALA_VERSION', '2.10.3'
  end

  it 'announces Scala 2.10.3' do
    should run 'echo Using Scala 2.10.3'
  end

  it 'runs sbt ++2.10.3 test if ./project directory exists' do
    directory('project')
    should run_script 'sbt ++2.10.3 test'
  end

  it 'runs sbt ++2.10.3 test if ./build.sbt exists' do
    file('build.sbt')
    should run_script 'sbt ++2.10.3 test'
  end

  it "runs sbt with sbt_args if they are given" do
    file("build.sbt")
    data["config"]["sbt_args"] = "-Dsbt.log.noformat=true"
    should run_script "sbt -Dsbt.log.noformat=true ++2.10.3 test"
  end
end
