require 'spec_helper'

describe Travis::Build::Script::Erlang, :sexp do
  let(:data)   { payload_for(:push, :erlang) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=erlang'] }
    let(:cmds) { ['rebar skip_deps=true eunit'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_OTP_RELEASE' do
    should include_sexp [:export, ['TRAVIS_OTP_RELEASE', 'R14B04']] #, echo: true
  end

  describe 'setup' do
    it 'activates otp' do
      should include_sexp [:cmd, 'source ${TRAVIS_HOME}/otp/R14B04/activate', assert: true, echo: true, timing: true]
    end

    it 'downloads OTP archive on demand when the desired release is not pre-installed' do
      branch = sexp_find(subject, [:if, '! -f ${TRAVIS_HOME}/otp/R14B04/activate'])
      expect(branch).to include_sexp [:raw, 'archive_url=https://s3.amazonaws.com/travis-otp-releases/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/erlang-R14B04-nonroot.tar.bz2', assert: true]
      expect(branch).to include_sexp [:cmd, 'wget -o ${TRAVIS_HOME}/erlang.tar.bz2 ${archive_url}', assert: true, echo: true, timing: true]
    end
  end

  describe 'install' do
    let(:sexp) { sexp_find(subject, [:if, '(-f rebar.config || -f Rebar.config) && -f ./rebar']) }

    it 'runs `./rebar get-deps` if both rebar config and ./rebar exist' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp [:cmd, './rebar get-deps', assert: true, echo: true, retry: true, timing: true]
    end

    it 'runs appropriate rebar command if rebar config exists, but ./rebar does not and rebar3 is not found' do
      branch = sexp_find(sexp, [:elif, '(-f rebar.config || -f Rebar.config)'])
      rebar_branch = sexp_find(branch, [:if, '-z $(command -v rebar3)'])
      expect(rebar_branch).to  include_sexp [:cmd, 'rebar get-deps', assert: true, echo: true, retry: true, timing: true]
    end
  end

  describe 'script' do
    let(:cond) { '(-f rebar.config || -f Rebar.config) && -f ./rebar' }
    let(:sexp) { sexp_filter(subject, [:if, cond])[1] }

    it 'runs `./rebar compile && ./rebar skip_deps=true eunit` if both rebar config and ./rebar exist' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp [:cmd, './rebar compile && ./rebar skip_deps=true eunit', echo: true, timing: true]
    end

    it 'runs appropriate rebar/rebar3 command if rebar config exists, but ./rebar does not' do
      branch = sexp_find(sexp, [:elif, '(-f rebar.config || -f Rebar.config)'])
      rebar3_branch = sexp_find(branch, [:if, '-n $(command -v rebar3)'])
      rebar_branch  = sexp_find(branch, [:else])
      expect(rebar3_branch).to include_sexp [:cmd, 'rebar3 eunit', echo: true, timing: true]
      expect(rebar_branch).to  include_sexp [:cmd, 'rebar compile && rebar skip_deps=true eunit',  echo: true, timing: true]
    end

    it 'runs `make test` if rebar config does not exist' do
      branch = sexp_filter(sexp, [:else])[1] # the first 'else' occurs in sh.if "command -v rebar3"
      expect(branch).to include_sexp [:cmd, "make test", echo: true, timing: true]
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq("cache-#{CACHE_SLUG_EXTRAS}--otp-R14B04") }
  end
end
