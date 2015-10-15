require 'spec_helper'

describe Travis::Build::Script::SmalltalkSqueak, :sexp do
  let(:data)   { payload_for(:push, :smalltalk_squeak) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=smalltalk_squeak'] }
    let(:cmds) { ['$FILETREE_CI_HOME/run.sh'] }
  end

  it "downloads and extracts correct script" do
    should include_sexp [:cmd, "wget -q -O filetreeCI.zip https://github.com/hpi-swa/filetreeCI/archive/master.zip", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "unzip -q -o filetreeCI.zip", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "cd filetreeCI-*", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "export FILETREE_CI_HOME=\"$(pwd)\"", assert: true, echo: true, timing: true]
  end

end
