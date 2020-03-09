require 'spec_helper'

describe Travis::Build::Script::Scala, :sexp do
  let(:data)   { payload_for(:push, :scala) }
  let(:script) { described_class.new(data) }
  let(:sbt_path) { '/usr/local/bin/sbt'}
  let(:sbt_sha) { '4ad1b8a325f75c1a66f3fd100635da5eb28d9c91'}
  let(:sbt_url) { "https://build.travis-ci.org/files/sbt"}

  before do
    Travis::Build.config.app_host = 'build.travis-ci.org'
  end

  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=scala'] }
    let(:cmds) { ['sbt ++2.12.8 test'] }
  end

  it_behaves_like 'a build script sexp'
  it_behaves_like 'a jvm build sexp'
  it_behaves_like 'announces java versions'

  it 'sets TRAVIS_SCALA_VERSION' do
    should include_sexp [:export, ['TRAVIS_SCALA_VERSION', '2.12.8']]
  end

  it 'announces Scala 2.12.8' do
    should include_sexp [:echo, 'Using Scala 2.12.8']
  end

  context "when scala version is given as an array" do
    before { data[:config][:scala] = %w( 2.12.1 )}
    it "exports TRAVIS_SCALA_VERSION given as the first value" do
      should include_sexp [:export, ['TRAVIS_SCALA_VERSION', '2.12.1']]
    end
  end

  let(:export_jvm_opts) { [:export, ['JVM_OPTS', '@/etc/sbt/jvmopts'], echo: true] }
  let(:export_sbt_opts) { [:export, ['SBT_OPTS', '@/etc/sbt/sbtopts'], echo: true] }

  describe 'if ./project directory or build.sbt file exists' do
    let(:sexp) { sexp_find(subject, [:if, '-d project || -f build.sbt'], [:if, "$? -ne 0"]) }

    it "updates SBT" do
      should include_sexp [:cmd, "curl -sf -o sbt.tmp #{sbt_url}"]
    end

    it 'sets JVM_OPTS' do
      should include_sexp export_jvm_opts
    end

    it 'sets SBT_OPTS' do
      should include_sexp export_sbt_opts
    end
  end

  describe 'script' do
    describe 'if ./project directory or build.sbt file exists' do
      let(:sexp) { sexp_find(sexp_filter(subject, [:if, '-d project || -f build.sbt'])[1], [:then]) }

      it 'runs sbt with default arguments' do
        expect(sexp).to include_sexp [:cmd, 'sbt ++2.12.8 test', echo: true, timing: true]
      end

      it 'runs sbt with additional arguments' do
        data[:config][:sbt_args] = '-Dsbt.log.noformat=true'
        expect(sexp).to include_sexp [:cmd, 'sbt -Dsbt.log.noformat=true ++2.12.8 test', echo: true, timing: true]
      end
    end
  end
end
