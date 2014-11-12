require 'spec_helper'

describe Travis::Build::Git::Clone, :sexp do
  let(:payload) { payload_for(:push, :ruby, oauth_token: 'secret') }
  let(:script)  { Travis::Build::Script.new(payload) }
  subject       { sexp_find(script.sexp, [:fold, 'git.tarball']) }

  let(:api)     { 'https://api.github.com/repos/travis-ci/travis-ci' }
  let(:url)     { "#{api}/tarball/313f61b" }
  let(:file)    { 'travis-ci-travis-ci.tar.gz' }
  let(:token)   { 'secret' }

  before :each do
    payload[:config][:git] = { strategy: 'tarball' }
    payload[:repository][:api_url] = api
  end

  it { store_example('git_tarball') }

  let(:mkdir)    { [:mkdir, 'travis-ci/travis-ci', recursive: true] }
  let(:curl)     { "curl -o #{file} -H \"Authorization: token #{token}\" -L #{url}" }
  let(:echo)     { "curl -o #{file} -H \"Authorization: token [SECURE]\" -L #{url}" }
  let(:download) { [:cmd, curl, assert: true, echo: echo, retry: true, timing: true] }
  let(:extract)  { [:cmd, "tar xfz #{file}", assert: true, echo: true, timing: true] }
  let(:move)     { [:mv, ['travis-ci-travis-ci-313f61b/*', 'travis-ci/travis-ci'], assert: true] }
  let(:cd)       { [:cd, 'travis-ci/travis-ci', echo: true] }

  it { should include_sexp mkdir }
  it { should include_sexp download }
  it { should include_sexp extract }
  it { should include_sexp move }
  it { should include_sexp cd }

  describe 'with a custom api_endpoint' do
    let(:api) { 'https://github.travis-ci.com/api/repos/travis-ci/travis-ci' }
    it { should include_sexp download }
  end
end
