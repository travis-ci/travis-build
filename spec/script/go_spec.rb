require 'spec_helper'

describe Travis::Build::Script::Go do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'sets GOPATH' do
    should set 'GOPATH', "#{Travis::Build::HOME_DIR}/gopath"
  end

  it 'creates the src dir' do
    should run "mkdir -p #{Travis::Build::HOME_DIR}/gopath/src"
  end

  describe 'if no makefile exists' do
    it 'installs with go get and go build' do
      should run 'echo $ go get -d -v ./... && go build -v ./...'
      should run 'go get -d -v ./...'
      should run 'go build -v ./...', log: true, assert: true, timeout: timeout_for(:install)
    end

    it 'runs go test' do
      should run_script 'go test -v ./...'
    end
  end

  describe 'if rebar.config exists' do
    before(:each) do
      file('Makefile')
    end

    it 'does not install with go get' do
      should_not run 'go get'
    end

    it 'runs make' do
      should run_script 'make'
    end
  end
end
