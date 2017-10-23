require 'spec_helper'

describe Travis::Build::Addons::Deploy::Config do
  let(:data)   { payload_for(:push) }
  let(:config) { {} }
  let(:object) { described_class.new(Travis::Build::Data.new(data), config) }

  shared_examples 'conditions' do |key|
    subject { object.on }

    describe 'moves a given String to the branch key' do
      let(:config) { { key => 'production' } }
      it { should include(branch: 'production') }
    end

    describe 'moves a given String to the branch key' do
      let(:config) { { key => 'production' } }
      it { should include(branch: 'production') }
    end

    describe 'turns a given :rvm key into a :ruby key' do
      let(:config) { { key => { rvm: '2.1.1' } } }
      it { should include(ruby: '2.1.1') }
    end

    describe 'turns a given :rvm key into a :ruby key' do
      let(:config) { { key => { node_js: '0.11' } } }
      it { should include(node: '0.11') }
    end

    describe 'accepts config on the key true' do
      let(:config) { { true => { branch: 'production' } } }
      it { should include(branch: 'production') }
    end

    describe 'accepts config on the key :true' do
      let(:config) { { true: { branch: 'production' } } }
      it { should include(branch: 'production') }
    end
  end

  describe 'on' do
    include_examples 'conditions', :on
  end

  describe 'if' do
    include_examples 'conditions', :if
  end

  describe 'branches' do
    subject { object.branches }

    describe 'returns on: :branch if given' do
      let(:config) { { on: { branch: { staging: {}, production: {} } } } }
      it { should eql [:staging, :production] }
    end

    describe 'returns keys from nested hashes (deprecated)' do
      let(:config) { { app: { staging: 'foo-staging', production: 'foo-production' } } }
      it { should eql [:staging, :production] }
    end
  end

  describe 'dpl_options' do
    subject { object.dpl_options }

    describe 'converts all except known keys to dpl shell options' do
      let(:config) { { app_id: 1, email: 'me@email.com', password: 'password' } }
      it { should eql '--app_id=1 --email=me@email.com --password=password' }
    end

    describe 'for the current branch' do
      describe 'merges configuration from on: branch' do
        let(:config) { { on: { branch: { master: { app_id: 1, api_key: 1 }, staging: { app_id: 2, api_key: 2 } } } } }
        it { should eql '--app_id=1 --api_key=1' }
      end
    end

    describe 'for the current branch (deprecated)' do
      describe 'adds keys from nested hashes' do
        let(:config) { { app_id: { master: 1, staging: 1 }, api_key: { master: 1, staging: 2 } } }
        it { should eql '--app_id=1 --api_key=1' }
      end

      describe 'works with arrays' do
        let(:config) { { app_id: [master: 1, staging: 1] } }
        it { should eql '--app_id=1' }
      end

      describe 'adds a blank option if true is given' do
        let(:config) { { doit: true } }
        it { should eql '--doit' }
      end

      describe 'does not add an options if nil is given' do
        let(:config) { { doit: nil } }
        it { should eql '' }
      end

      describe 'does not add an options if false is given' do
        let(:config) { { doit: false } }
        it { should eql '' }
      end
    end
  end

  describe 'edge?' do
    subject { object.edge? }

    describe 'returns true if given' do
      let(:config) { { edge: true } }
      it { should be true }
    end

    describe 'returns false if not given' do
      let(:config) { { edge: false } }
      it { should be false }
    end
  end

  describe 'assert?' do
    subject { object.assert? }

    describe 'returns true if :allow_failure was not given' do
      it { should be true }
    end

    describe 'returns true if :allow_failure was given' do
      let(:config) { { allow_failure: true } }
      it { should be false }
    end
  end

  describe 'stages' do
    subject { object.stages }

    describe 'returns before_deploy and after_deploy options if given' do
      let(:config) { { before_deploy: './foo', after_deploy: './bar', on: 'master' } }
      it { should eql(before_deploy: './foo', after_deploy: './bar') }
    end
  end
end
