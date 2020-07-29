require 'spec_helper'

describe Travis::Build::Git, :sexp do
  let(:payload) { payload_for(:push, :ruby) }
  let(:script)  { Travis::Build::Script.new(payload) }
  subject       { script.sexp }

  let(:rm_ssh_key)    { [:rm, '~/.ssh/source_rsa', force: true] }

  it { should include_sexp rm_ssh_key }

  describe 'config.keep_netrc' do
    context "with default configuration" do
      it 'does not delete .netrc' do
        should_not include_sexp [:raw, "rm -f ${TRAVIS_HOME}/.netrc"]
      end
    end

    context "when keep_netrc is true" do
      before { payload[:keep_netrc] = true }

      it 'does not delete .netrc' do
        should_not include_sexp [:raw, "rm -f ${TRAVIS_HOME}/.netrc"]
      end
    end

    context "when keep_netrc is false" do
      before { payload[:keep_netrc] = false }

      it 'deletes .netrc' do
        should include_sexp [:raw, "rm -f ${TRAVIS_HOME}/.netrc", assert: true]
      end
    end
  end
end
