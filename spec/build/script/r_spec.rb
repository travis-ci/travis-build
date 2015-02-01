require 'spec_helper'

describe Travis::Build::Script::R, :sexp do
  let (:data)   { payload_for(:push, :r) }
  let (:script) { described_class.new(data) }
  subject       { script.sexp }

  it_behaves_like 'a build script sexp'

  it 'exports TRAVIS_R_VERSION' do
    should include_sexp [:export, ['TRAVIS_R_VERSION', 'release']]
  end

  it 'downloads and installs R' do
    should include_sexp [:cmd, /sudo apt-get install.*r-base-dev/,
                         assert: true, echo: true, retry: true, timing: true]
  end

  describe 'bioc configuration is optional' do
    it 'does not install bioc if not required' do
      should_not include_sexp [:cmd, /.*biocLite.*/,
                               assert: true, echo: true, retry: true, timing: true]
    end

    it 'does install bioc if requested' do
      data[:config][:bioc_required] = true
      should include_sexp [:cmd, /.*biocLite.*/,
                           assert: true, echo: true, retry: true, timing: true]
    end

    it 'does install bioc with bioc_packages' do
      data[:config][:bioc_packages] = ['GenomicFeatures']
      should include_sexp [:cmd, /.*biocLite.*/,
                           assert: true, echo: true, retry: true, timing: true]
    end
  end

end
