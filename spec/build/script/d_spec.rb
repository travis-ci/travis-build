require 'spec_helper'

describe Travis::Build::Script::D, :sexp do
  let(:data)   { payload_for(:push, :d) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  after(:all) do
    #store_example
  end

  it_behaves_like 'a build script sexp'

  shared_examples 'dmd' do
    it 'downloads and installs dmd' do
      should include_sexp [:cmd, %r{downloads\.dlang\.org/releases/.*/dmd.*},
                           assert: true, echo: true, timing: true]
    end

    it 'downloads and installs dub' do
      should include_sexp [:cmd, %r{code\.dlang\.org/files/dub-.*},
                           assert: true, echo: true, timing: true]
    end

    it 'sets DC and DMD to dmd' do
      should include_sexp [:export, ['DC', 'dmd'], echo: true]
      should include_sexp [:export, ['DMD', 'dmd'], echo: true]
    end

    it 'announces dmd' do
      should include_sexp [:cmd, 'dmd --help | head -n 2', echo: true]
    end

    it 'announces dub' do
      should include_sexp [:cmd, 'dub --help | tail -n 1', echo: true]
    end

    it 'runs dub test with dmd' do
      should include_sexp [:cmd, 'dub test --compiler=dmd', echo: true, timing: true]
    end
  end

  context 'when no specific compiler is configured' do
    it_behaves_like 'dmd'
  end

  context 'when dmd is configured' do
    before do
      data[:config][:d] = 'dmd'
    end

    it_behaves_like 'dmd'

    it 'downloads the latest dmd version' do
      should include_sexp [:cmd, %r{LATEST_DMD=.*curl.*},
                           assert: true, timing: true]
      should include_sexp [:cmd, %r{downloads\.dlang\.org/releases/.*/dmd.*\${LATEST_DMD}.*\.zip},
                           assert: true, echo: true, timing: true]
    end
  end

  context 'when a dmd version is configured' do
    before do
      data[:config][:d] = 'dmd-2.066.0'
    end

    it_behaves_like 'dmd'

    it 'downloads a specific dmd version' do
      should include_sexp [:cmd, %r{downloads\.dlang\.org/releases/.*/dmd.*2\.066\.0.*\.zip},
                           assert: true, echo: true, timing: true]
    end
  end

  context 'when a prerelease version is configured' do
    before do
      data[:config][:d] = 'dmd-2.067.0-rc1'
    end

    it 'downloads from the prerelease path' do
      should include_sexp [:cmd, %r{downloads\.dlang\.org/pre-releases/2\.x/2\.067\.0/dmd.*2\.067\.0-rc1.*\.zip},
                           assert: true, echo: true, timing: true]
    end
  end

  context 'when a pre 2.065 version is configured' do
    before do
      data[:config][:d] = 'dmd-2.064.2'
    end

    it 'downloads from a folder without minor version' do
      should include_sexp [:cmd, %r{downloads\.dlang\.org/releases/2\.x/2\.064/dmd.*2\.064\.2.*\.zip},
                           assert: true, echo: true, timing: true]
    end
  end

  # LDC
  shared_examples 'ldc' do
    it 'sets DC and DMD from config :d' do
      should include_sexp [:export, ['DC', 'ldc2'], echo: true]
      should include_sexp [:export, ['DMD', 'ldmd2'], echo: true]
    end

    it 'announces ldc' do
      should include_sexp [:cmd, 'ldc2 --version', echo: true]
    end

    it 'runs dub test with ldc' do
      should include_sexp [:cmd, 'dub test --compiler=ldc2', echo: true, timing: true]
    end
  end

  context 'when ldc is configured' do
    before do
      data[:config][:d] = 'ldc'
    end

    it_behaves_like 'ldc'

    it 'downloads the latest ldc version' do
      should include_sexp [:cmd, %r{LATEST_LDC=.*curl.*},
                           assert: true, timing: true]
      should include_sexp [:cmd, %r{ldc/releases/download/.*/ldc2.*\${LATEST_LDC}.*.tar.*},
                           assert: true, echo: true, timing: true]
    end
  end

  context 'when a ldc version is configured' do
    before do
      data[:config][:d] = 'ldc-0.14.0'
    end

    it_behaves_like 'ldc'

    it 'downloads and installs ldc' do
      should include_sexp [:cmd, %r{ldc/releases/download/.*/ldc2.*0\.14\.0.*.tar.*},
                           assert: true, echo: true, timing: true]
    end
  end

  # GDC
  shared_examples 'gdc' do
    it 'sets DC and DMD from config :d' do
      should include_sexp [:export, ['DC', 'gdc'], echo: true]
      should include_sexp [:export, ['DMD', 'gdmd'], echo: true]
    end

    it 'announces gdc' do
      should include_sexp [:cmd, 'gdc --version', echo: true]
    end

    it 'runs dub test with gdc' do
      should include_sexp [:cmd, 'dub test --compiler=gdc', echo: true, timing: true]
    end
  end

  context 'when gdc is configured' do
    before do
      data[:config][:d] = 'gdc'
    end

    it_behaves_like 'gdc'

    it 'downloads and installs gdc' do
      should include_sexp [:cmd, %r{LATEST_GDC=.*curl.*},
                           assert: true, timing: true]
      should include_sexp [:cmd, %r{gdcproject\.org/downloads/.*\${LATEST_GDC}.*\.tar\..*},
                           assert: true, echo: true, timing: true]
    end
  end

  context 'when a gdc version is configured' do
    before do
      data[:config][:d] = 'gdc-4.8.2'
    end

    it_behaves_like 'gdc'

    it 'downloads and installs gdc' do
      should include_sexp [:cmd, %r{gdcproject\.org/downloads/.*4\.8\.2.*\.tar\..*},
                           assert: true, echo: true, timing: true]
    end
  end
end
