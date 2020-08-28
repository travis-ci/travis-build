require 'spec_helper'

describe Travis::Build::Script::Matlab, :sexp do
  let(:data)        { payload_for(:push, :matlab) }
  let(:script)      { described_class.new(data)   }
  let(:installer)   { Travis::Build::Script::Matlab::MATLAB_INSTALLER_LOCATION }
  let(:helper)      { Travis::Build::Script::Matlab::MATLAB_DEPS_LOCATION }
  let(:start)       { Travis::Build::Script::Matlab::MATLAB_START }
  let(:command)     { Travis::Build::Script::Matlab::MATLAB_COMMAND }
  let(:notice)      { Travis::Build::Script::Matlab::MATLAB_NOTICE }

  subject           { script.sexp }
  it                { store_example }

  it_behaves_like 'a bash script'

  it 'sets TRAVIS_MATLAB_VERSION to the latest version of MATLAB' do
    should include_sexp [:export, %w[TRAVIS_MATLAB_VERSION latest]]
  end

  it 'prints the support notice in green' do
    notice.each do |message|
      should include_sexp [:echo, message, ansi: :green]
    end
  end

  it 'configures runtime dependencies' do
    should include_sexp [:raw, "wget -qO- --retry-connrefused #{helper}"\
                         ' | sudo -E bash -s -- $TRAVIS_MATLAB_VERSION', assert: true]
  end

  context 'it sets up MATLAB' do
    it 'by calling the ephemeral installer script' do
      should include_sexp [:raw, "wget -qO- --retry-connrefused #{installer}"\
                           ' | sudo -E bash -s -- --release $TRAVIS_MATLAB_VERSION', assert: true]
    end
  end

  it 'runs the default MATLAB command' do
    should include_sexp [:cmd, "#{start} \"#{command}\"",
                         echo: true, timing: true]
  end
end
