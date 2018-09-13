require 'spec_helper'

describe Travis::Build::Addons::SauceConnect, :sexp do
  let(:script) { stub('script') }
  let(:config) { { username: 'username', access_key: 'access_key' } }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { sauce_connect: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }

  before do
    sc_data = Travis::Build.top.join('tmp/sc_data.json')
    sc_data.write("{}\n") unless sc_data.exist?
    addon.before_before_script
  end

  it_behaves_like 'compiled script' do
    let(:code) { ['sauce_connect', 'TRAVIS_SAUCE_CONNECT=true'] }
  end

  shared_examples_for 'starts sauce connect' do
    it { should include_sexp [:cmd, 'travis_start_sauce_connect', assert: true, echo: true, timing: true, retry: true] }
    it { should include_sexp [:export, ['TRAVIS_SAUCE_CONNECT', 'true']] }
  end

  shared_examples_for 'stops sauce connect' do
    it { should include_sexp [:cmd, 'travis_stop_sauce_connect', echo: true, timing: true] }
  end

  describe 'without credentials' do
    let(:config) { {} }

    it_behaves_like 'starts sauce connect'
  end

  describe 'with username and access key' do
    let(:config) { { :username => 'username', :access_key => 'access_key' } }

    it { should include_sexp [:export, ['SAUCE_USERNAME', 'username']] }
    it { should include_sexp [:export, ['SAUCE_ACCESS_KEY', 'access_key']] }

    it_behaves_like 'starts sauce connect'
    it { store_example }
  end

  describe 'with domain arguments' do
    let(:config) { { :direct_domains => 'travis-ci.org', :no_ssl_bump_domains=> 'travis-ci.org', :tunnel_domains => 'localhost' } }

    it { should include_sexp [:export, ['SAUCE_DIRECT_DOMAINS', "'-D travis-ci.org'"]] }
    it { should include_sexp [:export, ['SAUCE_NO_SSL_BUMP_DOMAINS', "'-B travis-ci.org'"]] }
    it { should include_sexp [:export, ['SAUCE_TUNNEL_DOMAINS', "'-t localhost'"]] }

    it_behaves_like 'starts sauce connect'
    it { store_example }
  end
end

