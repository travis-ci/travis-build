require 'ostruct'
require 'spec_helper'

describe Travis::Build::Addons::SshKnownHosts, :sexp do
  let(:script) { stub('script') }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { ssh_known_hosts: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_checkout }

  def add_host_cmd(host, port = nil)
    "ssh-keyscan -t $TRAVIS_SSH_KEY_TYPES#{" -p #{port}" if port} -H #{host} 2>&1 | tee -a ${TRAVIS_HOME}/.ssh/known_hosts"
  end

  context 'with multiple host config' do
    let(:config) { ['git.example.org', 'git.example.biz', 'custom.example.com:9999', '_zz$'] }

    it { should include_sexp [:cmd, add_host_cmd('git.example.org'), echo: true, timing: true] }
    it { should include_sexp [:cmd, add_host_cmd('git.example.biz'), echo: true, timing: true] }
    it { should include_sexp [:cmd, add_host_cmd('custom.example.com', 9999), echo: true, timing: true] }
    it { should_not include_sexp [:cmd, add_host_cmd('_zz$'), echo: true, timing: true] }
    it { store_example }
  end

  context 'with singular host config' do
    let(:config) { 'git.example.org' }

    it { should include_sexp [:cmd, add_host_cmd('git.example.org'), echo: true, timing: true] }
  end

  context 'without any hosts' do
    let(:config) { nil }

    it { should_not include_sexp [:cmd, add_host_cmd('git.example.org'), echo: true, timing: true] }
  end
end
