require 'spec_helper'

describe Travis::Build::Git, :sexp do
  let(:payload) { payload_for(:push, :ruby) }
  let(:script)  { Travis::Build::Script.new(payload) }
  subject       { script.sexp }

  let(:rm_ssh_key)    { [:rm, '~/.ssh/source_rsa', force: true] }

  it { should include_sexp rm_ssh_key }

  describe :checkout do
    context 'when using "tarball" strategy' do
      let(:api)      { 'https://api.github.com/repos/travis-ci/travis-ci' }
      let(:url)      { "#{api}/tarball/313f61b" }
      let(:file)     { 'travis-ci-travis-ci.tar.gz' }
      let(:curl)     { "curl -o #{file} -L #{url}" }
      let(:download) { [:cmd, curl, assert: true, echo: curl, retry: true, timing: true] }

      before :each do
        payload[:config][:git] = { strategy: 'tarball' }
        payload[:repository][:api_url] = api
      end

      context 'when building a pull request' do
        before :each do
          payload[:job][:pull_request] = '22'
        end

        it { should include_sexp [:echo, "\ntarball strategy is not supported on pull request builds"] }
        it { should_not include_sexp download }
      end

    end
  end
end
