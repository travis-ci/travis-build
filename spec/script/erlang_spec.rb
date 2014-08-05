require 'spec_helper'

describe Travis::Build::Script::Erlang do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'sets TRAVIS_OTP_RELEASE' do
    is_expected.to set 'TRAVIS_OTP_RELEASE', 'R14B04'
  end

  it 'activates otp' do
    is_expected.to travis_cmd "source ./otp/R14B04/activate"
  end

  describe 'if no rebar config exists' do
    it 'does not install rebar get-deps' do
      is_expected.not_to travis_cmd "./rebar get-deps", echo: true, timing: true, retry: true, assert: true
    end

    it 'runs make test' do
      is_expected.to travis_cmd "make test", echo: true, timing: true
    end
  end

  shared_examples_for 'runs rebar' do |path|
    it "installs #{path}rebar get-deps" do
      is_expected.to travis_cmd "#{path}rebar get-deps", echo: true, timing: true, retry: true, assert: true
    end

    it "runs #{path}rebar compile && #{path}rebar skip_deps=true eunit" do
      is_expected.to travis_cmd "#{path}rebar compile && #{path}rebar skip_deps=true eunit", echo: true, timing: true
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
