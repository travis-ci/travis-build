require 'spec_helper'

describe Travis::Build::Script::Erlang, :sexp do
  let(:data)   { payload_for(:push, :erlang) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=erlang'] }
    let(:cmds) { ['rebar skip_deps=true eunit'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_OTP_RELEASE' do
    should include_sexp [:export, ['TRAVIS_OTP_RELEASE', 'R14B04']] #, echo: true
  end

  it 'activates otp' do
    should include_sexp [:cmd, 'source $HOME/otp/R14B04/activate', assert: true, echo: true]
  end

  describe 'install' do
    let(:sexp) { sexp_find(subject, [:if, '(-f rebar.config || -f Rebar.config) && -f ./rebar']) }

    it 'runs `./rebar get-deps` if both rebar config and ./rebar exist' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp [:cmd, './rebar get-deps', assert: true, echo: true, retry: true, timing: true]
    end

    it 'runs `rebar get-deps` if rebar config exists, but ./rebar does not' do
      branch = sexp_find(sexp, [:elif, '(-f rebar.config || -f Rebar.config)'])
      expect(branch).to include_sexp [:cmd, 'rebar get-deps', assert: true, echo: true, retry: true, timing: true]
    end
  end

  describe 'script' do
    let(:cond) { '(-f rebar.config || -f Rebar.config) && -f ./rebar' }
    let(:sexp) { sexp_filter(subject, [:if, cond])[1] }

    it 'runs `./rebar compile && ./rebar skip_deps=true eunit` if both rebar config and ./rebar exist' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp [:cmd, './rebar compile && ./rebar skip_deps=true eunit', echo: true, timing: true]
    end

    it 'runs `rebar compile && rebar skip_deps=true eunit` if rebar config exists, but ./rebar does not' do
      branch = sexp_find(sexp, [:elif, '(-f rebar.config || -f Rebar.config)'])
      expect(branch).to include_sexp [:cmd, 'rebar compile && rebar skip_deps=true eunit', echo: true, timing: true]
    end

    it 'runs `make test` if rebar config does not exist' do
      branch = sexp_find(sexp, [:else])
      expect(branch).to include_sexp [:cmd, "make test", echo: true, timing: true]
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq('cache--otp-R14B04') }
  end

  context 'when elixir is defined' do
    it { store_example 'elixir config' }

    before(:each) { data[:config][:elixir] = '1.0.2' }

    it 'activates elixir' do
      should include_sexp [:cmd, 'source $HOME/.kiex/elixirs/elixir-1.0.2.env', echo: true, assert: true]
    end
  end
end

