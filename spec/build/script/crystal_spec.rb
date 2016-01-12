require 'spec_helper'

describe Travis::Build::Script::Crystal, :sexp do
  let(:data)   { payload_for(:push, :crystal) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'a build script sexp'

  it "announces `crystal --version`" do
    should include_sexp [:cmd, "crystal --version", echo: true]
  end

  it "announces `crystal deps --version`" do
    should include_sexp [:cmd, "crystal deps --version", echo: true]
  end

  it "runs tests by default" do
    should include_sexp [:cmd,
      "crystal spec",
      echo: true, timing: true]
  end

  context "versions" do
    it "installs latest released version by default" do
      should include_sexp [:cmd, "sudo apt-get install crystal"]
    end

    it "installs latest released version when explicitly asked for" do
      data[:config][:crystal] = "latest"
      should include_sexp [:cmd, "sudo apt-get install crystal"]
    end

    it "installs nightly when specified" do
      data[:config][:crystal] = "nightly"
      should include_sexp [:cmd, "sudo apt-get install crystal-nightly"]
    end

    it 'throws a error with a invalid version' do
      data[:config][:crystal] = "foo"
      should include_sexp [:echo, "\"foo\" is an invalid version of Crystal.\nView valid versions of Crystal at https://docs.travis-ci.com/user/languages/crystal/"]
    end
  end
end
