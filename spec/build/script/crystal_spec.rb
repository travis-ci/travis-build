require 'spec_helper'

describe Travis::Build::Script::Crystal, :sexp do
  let(:data)   { payload_for(:push, :crystal) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'a build script sexp'

  it "announces `crystal --version`" do
    should include_sexp [:cmd, "crystal --version", echo: true]
  end

  it "runs tests by default" do
    should include_sexp [:cmd,
      "crystal spec",
      echo: true, timing: true]
  end
end
