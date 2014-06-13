require 'spec_helper'

describe Travis::Build::Script::Erlang do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it_behaves_like 'a build script'

  it 'sets TRAVIS_OTP_RELEASE' do
    is_expected.to set 'TRAVIS_OTP_RELEASE', 'R14B04'
  end

  xit 'activates otp' do
    # for some reason the source stub doesn't work. can't source be overwritten in bash?
    executable 'otp/R14B04/activate' # should not be needed?
    is_expected.to run "source ~/otp/R14B04/activate"
  end

  describe 'if no rebar config exists' do
    it 'does not install rebar get-deps' do
      is_expected.not_to run 'rebar get-deps'
    end

    it 'runs make test' do
      is_expected.to run_script 'make test'
    end
  end

  shared_examples_for 'runs rebar' do |path|
    it "installs #{path}rebar get-deps" do
      is_expected.to run "#{path}rebar get-deps", echo: true, log: true, assert: true, retry: true
    end

    it "runs #{path}rebar compile && #{path}rebar skip_deps=true eunit" do
      is_expected.to run "echo $ #{path}rebar compile && #{path}rebar skip_deps=true eunit"
      is_expected.to run "#{path}rebar compile"
      is_expected.to run "#{path}rebar skip_deps=true eunit", log: true
    end
  end

  describe 'if rebar.config exists' do
    before(:each) { file('rebar.config') }
    it_behaves_like 'runs rebar'
  end

  describe 'if Rebar.config exists' do
    before(:each) { file('Rebar.config') }
    it_behaves_like 'runs rebar'
  end

  describe 'if ./rebar exists' do
    before(:each) do
      file       'rebar.config'
      executable './rebar'
    end

    it_behaves_like 'runs rebar', './'
  end

  describe '#cache_slug' do
    subject { described_class.new(data, options).cache_slug }
    it { is_expected.to eq('cache--otp-R14B04') }
  end
end
