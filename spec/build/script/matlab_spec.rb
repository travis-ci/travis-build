require 'spec_helper'

describe Travis::Build::Script::Matlab, :sexp do
  let(:data)        { payload_for(:push, :matlab) }
  let(:script)      { described_class.new(data)   }
  let(:installer)   { Travis::Build::Script::Matlab::MATLAB_INSTALLER_LOCATION }
  let(:start)       { Travis::Build::Script::Matlab::MATLAB_START }
  let(:command)     { Travis::Build::Script::Matlab::MATLAB_COMMAND }

  subject           { script.sexp }
  it                { store_example }

  it_behaves_like 'a bash script'

  it 'sets TRAVIS_MATLAB_VERSION to the latest version of MATLAB' do
    should include_sexp [:export, %w[TRAVIS_MATLAB_VERSION latest]]
  end

  context 'it uses the MATLAB installer' do
    it 'by discreetly downloading/piping it to a shell' do
      should include_sexp [:raw, "wget -qO- --retry-connrefused #{installer} "\
                           '| sudo -E bash']
    end
  end

  it 'runs the default MATLAB command' do
    should include_sexp [:cmd, "#{start} \"#{command}\"",
                         echo: true, timing: true]
  end
end
