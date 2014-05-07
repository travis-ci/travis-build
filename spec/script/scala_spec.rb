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
    should set 'TRAVIS_SCALA_VERSION', '2.10.4'
  end

  it 'announces Scala 2.10.4' do
    should run 'echo Using Scala 2.10.4'
  end

  it 'does not set JVM_OPTS' do
    should_not set 'JVM_OPTS'
  end

  it 'does not set SBT_OPTS' do
    should_not set 'SBT_OPTS'
  end

  shared_examples_for 'an sbt build' do

    it "sets JVM_OPTS" do
      should set 'JVM_OPTS', '@/etc/sbt/jvmopts'
    end

    it "sets SBT_OPTS" do
      should set 'SBT_OPTS', '@/etc/sbt/sbtopts'
    end

    context "without any sbt_args" do
      it "runs sbt with default arguments" do
        should run_script "sbt ++2.10.4 test"
      end
    end

    context "with some sbt_args defined" do
      before(:each) { data["config"]["sbt_args"] = "-Dsbt.log.noformat=true" }
      it "runs sbt with additional arguments" do
        should run_script "sbt -Dsbt.log.noformat=true ++2.10.4 test"
      end
    end

  end

  describe 'if ./project directory exists' do
    before(:each) { directory('project') }
    it_behaves_like 'an sbt build'
  end

  describe 'if ./build.sbt file exists' do
    before(:each) { file('build.sbt') }
    it_behaves_like 'an sbt build'
  end

end
