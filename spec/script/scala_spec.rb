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
    is_expected.to set 'TRAVIS_SCALA_VERSION', '2.10.4'
  end

  it 'announces Scala 2.10.4' do
    expect(log_for(subject)).to include('Using Scala 2.10.4')
  end

  it 'does not set JVM_OPTS' do
    is_expected.not_to travis_cmd 'export JVM_OPTS=@/etc/sbt/jvmopts', echo: true
  end

  it 'does not set SBT_OPTS' do
    is_expected.not_to travis_cmd 'export SBT_OPTS=@/etc/sbt/sbtopts', echo: true
  end

  shared_examples_for 'an sbt build' do
    it "sets JVM_OPTS" do
      is_expected.to travis_cmd 'export JVM_OPTS=@/etc/sbt/jvmopts', echo: true
    end

    it "sets SBT_OPTS" do
      is_expected.to travis_cmd 'export SBT_OPTS=@/etc/sbt/sbtopts', echo: true
    end

    context "without any sbt_args" do
      it "runs sbt with default arguments" do
        is_expected.to travis_cmd "sbt ++2.10.4 test", echo: true, timing: true
      end
    end

    context "with some sbt_args defined" do
      before(:each) { data["config"]["sbt_args"] = "-Dsbt.log.noformat=true" }
      it "runs sbt with additional arguments" do
        is_expected.to travis_cmd "sbt -Dsbt.log.noformat=true ++2.10.4 test", echo: true, timing: true
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
