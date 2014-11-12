require 'spec_helper'

describe Travis::Build::Git::SshKey, :sexp do
  let(:payload) { payload_for(:push, :ruby) }
  let(:script)  { Travis::Build::Script.new(payload) }
  subject       { script.sexp }

  let(:source_key)      { TEST_PRIVATE_KEY }

  let(:add_source_key)  { [:file, ['~/.ssh/id_rsa', source_key]] }
  let(:chmod_id_rsa)    { [:chmod, [600, '~/.ssh/id_rsa'], assert: true] }
  let(:start_ssh_agent) { [:raw, 'eval `ssh-agent` &> /dev/null', assert: true] }
  let(:add_ssh_key)     { [:raw, 'ssh-add ~/.ssh/id_rsa &> /dev/null', assert: true] }
  let(:add_known_hosts) { [:file, ['~/.ssh/config', "Host github.com\n\tBatchMode yes\n\tStrictHostKeyChecking no\n"], append: true] }

  describe 'was given' do
    before :each do
      payload[:config][:source_key] = Base64.encode64(source_key)
    end

    it { should include_sexp add_source_key }
    it { should include_sexp chmod_id_rsa }
    it { should include_sexp start_ssh_agent }
    it { should include_sexp add_ssh_key }
    it { should include_sexp add_known_hosts }
  end

  describe 'was not given' do
    it { should_not include_sexp add_source_key }
    it { should_not include_sexp chmod_id_rsa }
    it { should_not include_sexp start_ssh_agent }
    it { should_not include_sexp add_ssh_key }
    it { should_not include_sexp add_known_hosts }
  end
end
