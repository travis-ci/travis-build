require 'spec_helper'

describe Travis::Build::Addons do
  let(:script) { stub('script') }
  let(:sh)     { stub('sh') }
  let(:data)   { stub('data', disable_sudo?: !sudo) }
  let(:config) { { addons: { hosts: 'foo.bar' } } }
  let(:sudo)   { true }

  let(:stage)  { :before_prepare }
  let(:addon)  { described_class::Hosts.any_instance }
  let(:addons) { described_class.new(script, sh, data, config) }

  subject      { addons.run_stage(stage) }
  before       { addon.stubs(stage) }

  it 'passes the addon config' do
    described_class::Hosts.expects(:new).with(script, sh, data, config[:addons][:hosts]).returns(addon)
    subject
  end

  describe 'with an addon defining the given stage' do
    it 'runs the addon stage' do
      addon.expects(:before_prepare)
      subject
    end
  end

  describe 'with an addon not defining the given stage' do
    before { addon.stubs(:respond_to?).with(stage).returns(false) }

    it 'does not run the addon stage' do
      addon.expects(:before_prepare).never
      subject
    end
  end

  describe 'with an addon defining a predicate for the given stage' do
    before { addon.stubs(:respond_to?).with(stage).returns(true) }

    it 'runs the addon stage if the predicate returns true' do
      addon.stubs(:respond_to?).with(:"#{stage}?").returns(true)
      addon.stubs(:"#{stage}?").returns(true)
      addon.expects(:before_prepare)
      subject
    end

    it 'does not run the addon stage if the predicate returns false' do
      addon.stubs(:respond_to?).with(:"#{stage}?").returns(false)
      addon.stubs(:"#{stage}?").returns(false)
      addon.expects(:before_prepare).never
      subject
    end
  end

  describe 'with sudo disabled' do
    let(:sudo) { false }

    describe 'with a sudo safe addon' do
      it 'runs the stage' do
        addon.expects(:before_prepare)
        subject
      end
    end

    describe 'with a non sudo safe addon' do
      let(:config) { { addons: { firefox: '20.0' } } }
      let(:addon)  { described_class::Firefox.any_instance }

      it 'does not run the stage' do
        addon.expects(:before_prepare).never
        subject
      end
    end
  end

  describe 'does not explode' do
    let(:config) { { addons: { missing: 'typo' } } }

    it 'if the addon does not exist' do
      expect { subject }.to_not raise_error
    end
  end
end
