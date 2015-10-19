require 'spec_helper'

describe Travis::Build::Script::Smalltalk, :sexp do
  let(:data)   { payload_for(:push, :smalltalk) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=smalltalk'] }
    let(:cmds) { ['$FILETREE_CI_HOME/run.sh'] }
  end

  it "downloads and extracts correct script" do
    should include_sexp [:cmd, "wget -q -O filetreeCI.zip https://github.com/hpi-swa/filetreeCI/archive/master.zip", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "unzip -q -o filetreeCI.zip", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "cd filetreeCI-*", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "export FILETREE_CI_HOME=\"$(pwd)\"", assert: true, echo: true, timing: true]
  end

  it "falls back to the default smalltalk version if no other is defined" do
    expect(sexp_find(subject, [:if, '-z "$SMALLTALK"'])).to include_sexp [:export, ['SMALLTALK', 'Squeak5.0'], echo: true]
  end

end
