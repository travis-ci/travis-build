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
    should include_sexp [:cmd, "pushd filetreeCI-*", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "export FILETREE_CI_HOME=\"$(pwd)\"", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "popd; popd", assert: true, echo: true, timing: true]
  end

  describe 'set smalltalk version' do
    before do
      data[:config][:smalltalk] = 'Squeak5.0'
    end

    it 'sets SMALLTALK to correct version' do
      should include_sexp [:export, ['SMALLTALK', 'Squeak5.0']]
    end
  end

end
