require 'spec_helper'

describe Travis::Build::Script::Go, :sexp do
  let(:data)   { payload_for(:push, :go) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=go', 'go test'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets GOPATH' do
    should include_sexp [:export, ['GOPATH', '$HOME/gopath:$GOPATH']]
  end

  it 'sets TRAVIS_GO_VERSION' do
    should include_sexp [:export, ['TRAVIS_GO_VERSION', 'go1.3.3']]
  end

  it 'updates GVM' do
    should include_sexp [:cmd, 'gvm get', assert: true, echo: true, timing: true]
  end

  it 'fetches the latest Go code' do
    should include_sexp [:cmd, 'gvm update && source $HOME/.gvm/scripts/gvm', assert: true, echo: true, timing: true]
  end

  it 'sets the default go version if not :go config given' do
    should include_sexp [:cmd, 'gvm use go1.3.3', assert: true, echo: true, timing: true]
  end

  it 'sets the go version from config :go' do
    data[:config][:go] = 'go1.1'
    should include_sexp [:cmd, 'gvm use go1.1', assert: true, echo: true, timing: true]
  end

  shared_examples 'gopath fix' do
    it { should include_sexp [:mkdir, "$HOME/gopath/src/#{hostname}/travis-ci/travis-ci", echo: true, recursive: true] }
    it { should include_sexp [:cmd, "rsync -az ${TRAVIS_BUILD_DIR}/ $HOME/gopath/src/#{hostname}/travis-ci/travis-ci/", echo: true] }
    it { should include_sexp [:export, ['TRAVIS_BUILD_DIR', "$HOME/gopath/src/#{hostname}/travis-ci/travis-ci"], echo: true] }
    it { should include_sexp [:cd, "$HOME/gopath/src/#{hostname}/travis-ci/travis-ci", echo: true] }
  end

  describe 'with github.com' do
    let(:hostname) { 'github.com' }
    it_behaves_like 'gopath fix'
  end

  describe 'with ghs' do
    let(:hostname) { 'ghe.example.com' }

    before do
      data[:repository]['source_url'] = "git@#{hostname}:travis-ci/travis-ci.git"
    end

    it_behaves_like 'gopath fix'
  end

  it 'installs the gvm version' do
    data[:config][:go] = 'go1.1'
    should include_sexp [:cmd, 'gvm install go1.1 --binary || gvm install go1.1', assert: true, echo: true, timing: true]
  end

  versions = { '1.1' => 'go1.1', '1' => 'go1.3.3', '1.2' => 'go1.2.2', '1.0' => 'go1.0.3', '1.2.2' => 'go1.2.2', '1.0.2' => 'go1.0.2' }
  versions.each do |version_alias, version|
    it "sets version #{version.inspect} for alias #{version_alias.inspect}" do
      data[:config][:go] = version_alias
      should include_sexp [:cmd, "gvm install #{version} --binary || gvm install #{version}", assert: true, echo: true, timing: true]
    end
  end

  it 'passes through arbitrary tag versions' do
    data[:config][:go] = 'release9000'
    should include_sexp [:cmd, 'gvm install release9000 --binary || gvm install release9000', assert: true, echo: true, timing: true]
  end

  it 'announces go version' do
    should include_sexp [:cmd, 'go version', echo: true]
  end

  it 'announces gvm version' do
    should include_sexp [:cmd, 'gvm version', echo: true]
  end

  it 'announces go env' do
    should include_sexp [:cmd, 'go env', echo: true]
  end

  %w(1.0.3 1.1 1.1.2).each do |old_go_version|
    describe "if no Makefile exists on #{old_go_version}" do
      it 'installs with go get' do
        data[:config][:go] = old_go_version
        should include_sexp [:cmd, 'go get -v ./...', echo: true, timing: true, retry: true, assert: true]
      end
    end
  end

  %w(1 1.2 1.2.2 1.3).each do |recent_go_version|
    describe "if no Makefile exists on #{recent_go_version}" do
      it 'installs with go get -t' do
        data[:config][:go] = recent_go_version
        should include_sexp [:cmd, 'go get -t -v ./...', echo: true, timing: true, retry: true, assert: true]
      end
    end
  end

  makefiles = %w(GNUmakefile makefile Makefile BSDmakefile)
  makefiles.each do |makefile|
    describe "if #{makefile} exists" do
      let(:cond) { makefiles.map { |makefile| "-f #{makefile}" }.join(' || ') }
      let(:sexp) { sexp_find(sexp_filter(subject, [:if, cond])[1], [:then]) }

      it 'does not install with go get' do
        expect(sexp.join).not_to include('go get')
      end

      it 'runs make' do
        expect(sexp).to include_sexp [:cmd, 'make', echo: true, timing: true]
      end
    end
  end
end

