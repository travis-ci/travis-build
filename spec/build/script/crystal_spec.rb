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
    it { is_expected.to eq("cache-#{CACHE_SLUG_EXTRAS}-crystal-stable") }
  end

  context "versions" do
    it "installs latest linux release by default" do
      data[:config][:os] = "linux"
      should include_sexp [:cmd, %q(echo "deb https://dl.bintray.com/crystal/deb all stable" | sudo tee /etc/apt/sources.list.d/crystal.list)]
      should include_sexp [:cmd, "sudo apt-get install -y crystal"]
    end

    it "installs latest macOS release by default" do
      data[:config][:os] = "osx"
      should include_sexp [:cmd, "brew install crystal-lang"]
    end

    it "installs latest stable linux release (with crystal: latest)" do
      data[:config][:os] = "linux"
      data[:config][:crystal] = "latest"
      should include_sexp [:cmd, %q(echo "deb https://dl.bintray.com/crystal/deb all stable" | sudo tee /etc/apt/sources.list.d/crystal.list)]
      should include_sexp [:cmd, "sudo apt-get install -y crystal"]
    end

    %w(stable unstable nightly).each do |channel|
      it "installs latest stable linux release (with crystal: #{channel})" do
        data[:config][:os] = "linux"
        data[:config][:crystal] = channel
        should include_sexp [:cmd, %Q(echo "deb https://dl.bintray.com/crystal/deb all #{channel}" | sudo tee /etc/apt/sources.list.d/crystal.list)]
        should include_sexp [:cmd, "sudo apt-get install -y crystal"]
      end

      %w(0.35 1.0.1 1.1.0-pre3).each do |version|
        it "installs specific channel/version linux release (with crystal: #{channel}/#{version})" do
          data[:config][:os] = "linux"
          data[:config][:crystal] = "#{channel}/#{version}"
          should include_sexp [:cmd, %Q(echo "deb https://dl.bintray.com/crystal/deb all #{channel}" | sudo tee /etc/apt/sources.list.d/crystal.list)]
          should include_sexp [:cmd, %Q(sudo apt-get install -y crystal="#{version}*")]
        end
      end
    end

    %w(0.35 1.0.1 1.1.0-pre3).each do |version|
      it "installs specific stable version release (with crystal: #{version})" do
        data[:config][:os] = "linux"
        data[:config][:crystal] = version
        should include_sexp [:cmd, %Q(echo "deb https://dl.bintray.com/crystal/deb all stable" | sudo tee /etc/apt/sources.list.d/crystal.list)]
        should include_sexp [:cmd, %Q(sudo apt-get install -y crystal="#{version}*")]
      end
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

    %w(foo wrong1.0.0 notstable).each do |invalid_version|
      # wrong1.0.0 and notstable were choosed to check valid values as suffix
      it "throws a error with a invalid version (with crystal: #{invalid_version}" do
        data[:config][:crystal] = invalid_version
        should include_sexp [:echo, "\"#{invalid_version}\" is an invalid version of Crystal.\nView valid versions of Crystal at https://docs.travis-ci.com/user/languages/crystal/"]
      end
    end
  end
end
