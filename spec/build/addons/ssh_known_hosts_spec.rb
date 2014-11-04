require 'ostruct'
require 'spec_helper'

describe Travis::Build::Addons::SshKnownHosts, :sexp do
  # subject { described_class.new(script, config) }

  # let(:script) { stub_everything('script') }
  # let(:data) do
  #   OpenStruct.new.tap do |o|
  #     o.pull_request = false
  #     o.branch = 'master'
  #     o.slug = 'missing/link'
  #     o.build = { number: '123' }
  #     o.job = { number: '123.1' }
  #   end
  # end

  # before(:each) do
  #   script.stubs(:fold).yields(script)
  #   script.stubs(:data).returns(data)
  #   script.stubs(:echo)
  # end

  let(:data)   { payload_for(:push, :ruby, config: { addons: { ssh_known_hosts: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_checkout }

  def add_host_cmd(host)
    "ssh-keyscan -t rsa,dsa -H #{host} 2>&1 | tee -a #{Travis::Build::HOME_DIR}/.ssh/known_hosts"
  end

  context 'with multiple host config' do
    let(:config) { ['git.example.org', 'git.example.biz'] }

    it { should include_sexp [:cmd, add_host_cmd('git.example.org')] }
    it { should include_sexp [:cmd, add_host_cmd('git.example.biz')] }
  end

  context 'with singular host config' do
    let(:config) { 'git.example.org' }

    it { should include_sexp [:cmd, add_host_cmd('git.example.org')] }
  end

  context 'without any hosts' do
    let(:config) { nil }

    it { should_not include_sexp [:cmd, add_host_cmd('git.example.org')] }
  end
end
