require 'spec_helper'

describe Travis::Build::Script::Go do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it_behaves_like 'a build script'

  it 'sets GOPATH' do
    is_expected.to set 'GOPATH', %r@[^:]*#{Travis::Build::HOME_DIR}/gopath:.*@
  end

  it 'sets TRAVIS_GO_VERSION' do
    is_expected.to set 'TRAVIS_GO_VERSION', 'go1.2.2'
  end

  it 'updates GVM' do
    is_expected.to setup 'gvm get'
  end

  it 'fetches the latest Go code' do
    is_expected.to run %r|gvm update && source #{Travis::Build::HOME_DIR}/.gvm/scripts/gvm|
  end

  it 'sets the default go version if not :go config given' do
    is_expected.to setup 'gvm use go1.2.2'
  end

  it 'sets the go version from config :go' do
    data['config']['go'] = 'go1.1'
    is_expected.to setup 'gvm use go1.1'
  end

  it 'creates the src dir' do
    is_expected.to run "mkdir -p #{Travis::Build::HOME_DIR}/gopath/src/github.com/travis-ci"
  end

  it "copies the repository to the GOPATH" do
    is_expected.to run "cp -r #{Travis::Build::BUILD_DIR}/travis-ci/travis-ci #{Travis::Build::HOME_DIR}/gopath/src/github.com/travis-ci/travis-ci"
  end

  it "updates TRAVIS_BUILD_DIR" do
    is_expected.to set "TRAVIS_BUILD_DIR", "#{Travis::Build::HOME_DIR}/gopath/src/github.com/travis-ci/travis-ci"
  end

  it "cds to the GOPATH version of the project" do
    is_expected.to run "cd #{Travis::Build::HOME_DIR}/gopath/src/github.com/travis-ci/travis-ci"
  end

  context "on a GHE instance" do
    before do
      data['repository']['source_url'] = 'git@ghe.example.com:travis-ci/travis-ci.git'
    end

    it 'creates the src dir' do
      is_expected.to run "mkdir -p #{Travis::Build::HOME_DIR}/gopath/src/ghe.example.com/travis-ci"
    end

    it "copies the repository to the GOPATH" do
      is_expected.to run "cp -r #{Travis::Build::BUILD_DIR}/travis-ci/travis-ci #{Travis::Build::HOME_DIR}/gopath/src/ghe.example.com/travis-ci/travis-ci"
    end

    it "updates TRAVIS_BUILD_DIR" do
      is_expected.to set "TRAVIS_BUILD_DIR", "#{Travis::Build::HOME_DIR}/gopath/src/ghe.example.com/travis-ci/travis-ci"
    end

    it "cds to the GOPATH version of the project" do
      is_expected.to run "cd #{Travis::Build::HOME_DIR}/gopath/src/ghe.example.com/travis-ci/travis-ci"
    end
  end

  it 'installs the gvm version' do
    data['config']['go'] = 'go1.1'
    is_expected.to run 'gvm install go1.1'
  end

  {'1.1' => 'go1.1', '1' => 'go1.2.2', '1.0' => 'go1.0.3', '1.0.2' => 'go1.0.2'}.each do |version_alias,version|
    it "sets version #{version.inspect} for alias #{version_alias.inspect}" do
      data['config']['go'] = version_alias
      is_expected.to run "gvm install #{version}"
    end
  end

  it 'passes through arbitrary tag versions' do
    data['config']['go'] = 'release9000'
    is_expected.to run 'gvm install release9000'
  end

  it 'announces go version' do
    is_expected.to announce 'go version'
  end

  it 'announces gvm version' do
    is_expected.to announce 'gvm version'
  end

  it 'announces go env' do
    is_expected.to announce 'go env'
  end

  it 'folds go env' do
    is_expected.to fold 'go env', 'go.env'
  end

  it 'folds gvm install' do
    is_expected.to fold 'gvm install', 'gvm.install'
  end

  describe 'if no Makefile exists' do
    it 'installs with go get' do
      is_expected.to run 'echo $ go get -v ./...'
      is_expected.to run 'go get -v ./...', log: true, assert: true
    end

    it 'runs go test' do
      is_expected.to run_script 'go test -v ./...'
    end
  end

  %w(GNUmakefile makefile Makefile BSDmakefile).each do |makefile_name|
    describe "if #{makefile_name} exists" do
      before(:each) do
        file(makefile_name)
      end

      it 'does not install with go get' do
        is_expected.not_to run 'go get'
      end

      it 'runs make' do
        is_expected.to run_script 'make'
      end
    end
  end
end
