require 'spec_helper'

describe Travis::Build::Script::Crystal, :sexp do
  let(:data)   { payload_for(:push, :crystal) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'
  it_behaves_like 'a build script sexp'

  it "announces `crystal --version`" do
    should include_sexp [:cmd, "crystal --version", echo: true]
  end

  it "announces `shards --version`" do
    should include_sexp [:cmd, "shards --version", echo: true]
  end

  it "runs tests by default" do
    should include_sexp [:cmd,
      "crystal spec",
      echo: true, timing: true]
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq("cache-#{CACHE_SLUG_EXTRAS}-crystal-latest") }
  end

  context "versions" do
    let(:with_snap) { sexp_find(subject, [:if, '-n $(command -v snap)'], [:then]) }
    let(:without_snap) { sexp_find(subject, [:if, '-n $(command -v snap)'], [:else]) }

    it "installs latest linux release by default" do
      data[:config][:os] = "linux"
      expect(with_snap).to include_sexp [:cmd, "sudo snap install crystal --classic --channel=latest/stable", {echo: true}]
      expect(without_snap).to include_sexp [:cmd, "sudo apt-get install -y crystal libgmp-dev"]
    end

    it "installs latest macOS release by default" do
      data[:config][:os] = "osx"
      should include_sexp [:cmd, "brew install crystal-lang"]
    end

    it "installs latest linux release when explicitly asked for" do
      data[:config][:os] = "linux"
      data[:config][:crystal] = "latest"
      expect(with_snap).to include_sexp [:cmd, "sudo snap install crystal --classic --channel=latest/stable", {echo: true}]
    end

    it "installs linux nightly when specified" do
      data[:config][:os] = "linux"
      data[:config][:crystal] = "nightly"
      expect(with_snap).to include_sexp [:cmd, "sudo snap install crystal --classic --channel=latest/edge", {echo: true}]
      expect(without_snap).to include_sexp [:echo, "Crystal nightlies will only be supported via snap. Use Xenial or later releases."]
    end

    it 'throws a error with a non-release version on macOS' do
      data[:config][:os] = "osx"
      data[:config][:crystal] = "nightly"
      should include_sexp [:echo, "Specifying Crystal version is not yet supported by the macOS environment"]
    end

    it 'throws a error with an invalid OS' do
      data[:config][:os] = "invalid"
      should include_sexp [:echo, "Operating system not supported: \"invalid\""]
    end

    it 'throws a error with a invalid version' do
      data[:config][:crystal] = "foo"
      should include_sexp [:echo, "\"foo\" is an invalid version of Crystal.\nView valid versions of Crystal at https://docs.travis-ci.com/user/languages/crystal/"]
    end
  end
end
