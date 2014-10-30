require 'ostruct'
require 'spec_helper'

describe Travis::Build::Script::Addons::SshKnownHosts do
  subject { described_class.new(script, config) }

  let(:script) { stub_everything('script') }
  let(:data) do
    OpenStruct.new.tap do |o|
      o.pull_request = false
      o.branch = 'master'
      o.slug = 'missing/link'
      o.build = { number: '123' }
      o.job = { number: '123.1' }
    end
  end

  before(:each) do
    script.stubs(:fold).yields(script)
    script.stubs(:data).returns(data)
    script.stubs(:echo)
  end

  context 'with multiple host config' do
    let(:config) do
      ['git.example.org', 'git.example.biz']
    end

    it "adds hosts to ~/.ssh/known_hosts" do
      script.expects(:cmd).with(%Q{ssh-keyscan -H git.example.org >> #{Travis::Build::HOME_DIR}/.ssh/known_hosts 2>/dev/null}, assert: false)
      script.expects(:cmd).with(%Q{ssh-keyscan -H git.example.biz >> #{Travis::Build::HOME_DIR}/.ssh/known_hosts 2>/dev/null}, assert: false)
      subject.before_checkout
    end
  end

  context 'with singular host config' do
    let(:config) do
      'git.example.org'
    end

    it 'adds host to ~/.ssh/known_hosts' do
      script.expects(:cmd).with(%Q{ssh-keyscan -H git.example.org >> #{Travis::Build::HOME_DIR}/.ssh/known_hosts 2>/dev/null}, assert: false)
      subject.before_checkout
    end
  end

  context 'without any hosts' do
    let(:config) { nil }

    it 'does not add known hosts' do
      script.expects(:cmd).never
      subject.before_checkout
    end
  end
end
