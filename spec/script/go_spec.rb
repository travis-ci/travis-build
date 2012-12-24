require 'spec_helper'

describe Travis::Build::Script::Go do
  let(:config) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(config).compile }

  it_behaves_like 'a build script'

  it 'sets GOPATH' do
    should set 'GOPATH', "#{Travis::Build::HOME_DIR}/gopath"
  end

  it 'creates the src dir' do
    should run "mkdir -p #{Travis::Build::HOME_DIR}/gopath/src"
  end

  describe 'if no makefile exists' do
    it 'installs with go get and go build' do
      should run 'echo $ go get -d -v && go build -v'
      should run 'go get -d -v'
      should run 'go build -v', log: true, assert: true, timeout: timeout_for(:install)
    end

    it 'runs go test -v' do
      should run 'go test -v', echo: true, log: true, timeout: timeout_for(:script)
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
      should run 'make', echo: true, log: true, timeout: timeout_for(:script)
    end
  end
end
