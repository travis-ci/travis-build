require 'spec_helper'

describe Travis::Build::Script::R, :sexp do
  let (:data)   { payload_for(:push, :r) }
  let (:script) { described_class.new(data) }
  subject       { script.sexp }
  it            { store_example }

  it_behaves_like 'a build script sexp'

  it 'normalizes bioc-devel correctly' do
    pending('known to fail with certain random seeds (incl 58438)')
    fail
    data[:config][:r] = 'bioc-devel'
    should include_sexp [:export, ['TRAVIS_R_VERSION', 'devel']]
    should include_sexp [:cmd, %r{source\(\"https://bioconductor.org/biocLite.R\"\)},
                         assert: true, echo: true, timing: true, retry: true]
    should include_sexp [:cmd, %r{useDevel\(TRUE\)},
                         assert: true, echo: true, timing: true, retry: true]
  end

  it 'normalizes bioc-release correctly' do
    pending('known to fail with certain random seeds (incl 58438)')
    fail
    data[:config][:r] = 'bioc-release'
    should include_sexp [:cmd, %r{source\(\"https://bioconductor.org/biocLite.R\"\)},
                         assert: true, echo: true, timing: true, retry: true]
    should include_sexp [:export, ['TRAVIS_R_VERSION', '3.3.1']]
  end

  it 'r_packages works with a single package set' do
    data[:config][:r_packages] = 'test'
    should include_sexp [:cmd, %r{install\.packages\(c\(\"test\"\)\)},
                         assert: true, echo: true, timing: true]
  end

  it 'r_packages works with multiple packages set' do
    data[:config][:r_packages] = ['test', 'test2']
    should include_sexp [:cmd, %r{install\.packages\(c\(\"test\", \"test2\"\)\)},
                         assert: true, echo: true, timing: true]
  end

  it 'exports TRAVIS_R_VERSION' do
    data[:config][:r] = '3.3.0'
    should include_sexp [:export, ['TRAVIS_R_VERSION', '3.3.0']]
  end

  it 'downloads and installs latest R' do
    should include_sexp [:cmd, %r{^curl.*https://s3\.amazonaws\.com/rstudio-travis/R-3\.3\.1\.xz},
                         assert: true, echo: true, retry: true, timing: true]
  end

  it 'downloads and installs latest R on OS X' do
    data[:config][:os] = 'osx'
    should include_sexp [:cmd, %r{^curl.*bin/macosx/R-latest\.pkg},
                         assert: true, echo: true, retry: true, timing: true]
  end

  it 'downloads and installs aliased R 3.2.5 on OS X' do
    data[:config][:os] = 'osx'
    data[:config][:r] = '3.2.5'
    should include_sexp [:cmd, %r{^curl.*bin/macosx/old/R-3\.2\.4-revised\.pkg},
                         assert: true, echo: true, retry: true, timing: true]
  end
  it 'downloads and installs other R versions on OS X' do
    data[:config][:os] = 'osx'
    data[:config][:r] = '3.1.3'
    should include_sexp [:cmd, %r{^curl.*bin/macosx/old/R-3\.1\.3\.pkg},
                         assert: true, echo: true, retry: true, timing: true]
  end
  it 'downloads and installs R devel on OS X' do
    data[:config][:os] = 'osx'
    data[:config][:r] = 'devel'
    should include_sexp [:cmd, %r{^curl.*r\.research\.att\.com/mavericks/R-devel/R-devel-mavericks-signed\.pkg},
                         assert: true, echo: true, retry: true, timing: true]
  end
  it 'downloads and installs gfortran libraries on OS X' do
    data[:config][:os] = 'osx'
    should include_sexp [:cmd, %r{^curl.*#{Regexp.escape('/tmp/gfortran.tar.bz2 http://r.research.att.com/libs/gfortran-4.8.2-darwin13.tar.bz2')}},
                         assert: true, echo: true, retry: true, timing: true]
  end

  it 'downloads and installs R 3.1' do
    data[:config][:r] = '3.1'
    should include_sexp [:cmd, %r{^curl.*https://s3\.amazonaws\.com/rstudio-travis/R-3\.1\.3\.xz},
                         assert: true, echo: true, retry: true, timing: true]
  end

  it 'downloads and installs R 3.2' do
    data[:config][:r] = '3.2'
    should include_sexp [:cmd, %r{^curl.*https://s3\.amazonaws\.com/rstudio-travis/R-3\.2\.5\.xz},
                         assert: true, echo: true, retry: true, timing: true]
  end

  it 'downloads and installs R devel' do
    data[:config][:r] = 'devel'
    should include_sexp [:cmd, %r{^curl.*https://s3\.amazonaws\.com/rstudio-travis/R-devel\.xz},
                         assert: true, echo: true, retry: true, timing: true]
  end

  it 'downloads pandoc and installs into /usr/bin/pandoc' do
    data[:config][:pandoc_version] = '1.15.2'
    should include_sexp [:cmd, %r{curl -Lo /tmp/pandoc-1\.15\.2-1-amd64\.deb https://github\.com/jgm/pandoc/releases/download/1\.15\.2/pandoc-1\.15\.2-1-amd64\.deb},
                         assert: true, echo: true, timing: true]

    should include_sexp [:cmd, %r{sudo dpkg -i /tmp/pandoc-},
                         assert: true, echo: true, timing: true]
  end

  it 'sets repos in ~/.Rprofile.site with defaults' do
    data[:config][:cran] = 'https://cloud.r-project.org'
    should include_sexp [:cmd, "echo 'options(repos = c(CRAN = \"https://cloud.r-project.org\"))' > ~/.Rprofile.site",
                         assert: true, echo: true, timing: true]
  end

  it 'sets repos in ~/.Rprofile.site with user specified repos' do
    data[:config][:cran] = 'https://cran.rstudio.org'
    should include_sexp [:cmd, "echo 'options(repos = c(CRAN = \"https://cran.rstudio.org\"))' > ~/.Rprofile.site",
                         assert: true, echo: true, timing: true]
  end

  it 'sets repos in ~/.Rprofile.site with additional user specified repos' do
    data[:config][:repos] = {CRAN: 'https://cran.rstudio.org', ropensci: 'http://packages.ropensci.org'}
    should include_sexp [:cmd, "echo 'options(repos = c(CRAN = \"https://cran.rstudio.org\", ropensci = \"http://packages.ropensci.org\"))' > ~/.Rprofile.site",
                         assert: true, echo: true, timing: true]
  end

  it 'installs binary devtools if sudo: required' do
    data[:config][:sudo] = 'required'
    should include_sexp [:cmd, /sudo apt-get install.*r-cran-devtools/,
                         assert: true, echo: true, timing: true, retry: true]
  end

  it 'installs source devtools if sudo: is missing' do
    should include_sexp [:cmd, /Rscript -e 'install\.packages\(c\(\"devtools\"\)/,
                         assert: true, echo: true, timing: true]

    should_not include_sexp [:cmd, /sudo apt-get install.*r-cran-devtools/,
                         assert: true, echo: true, timing: true, retry: true]
  end

  it 'installs source devtools if sudo: false' do
    data[:config][:sudo] = false
    should include_sexp [:cmd, /Rscript -e 'install\.packages\(c\(\"devtools\"\)/,
                         assert: true, echo: true, timing: true]

    should_not include_sexp [:cmd, /sudo apt-get install.*r-cran-devtools/,
                         assert: true, echo: true, timing: true, retry: true]
  end

  it 'fails on package build and test failures' do
    should include_sexp [:cmd, /.*R CMD build.*/,
                         assert: true, echo: true, timing: true]
    should include_sexp [:cmd, /.*R CMD check.*/,
                         echo: true, timing: true]
  end

  it 'skips PDF manual when LaTeX is disabled' do
    data[:config][:latex] = false
    should include_sexp [:cmd, /.*R CMD check.* --no-manual.*/,
                         echo: true, timing: true]
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

    it 'Prints installed package versions' do
      should include_sexp [:cmd, /.*#{Regexp.escape('devtools::session_info(installed.packages()[, "Package"])')}.*/,
                           assert: true, echo: true, timing: true]
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it {
      data[:config][:r] = '3.3.0'
      should eq("cache-#{CACHE_SLUG_EXTRAS}--R-3.3.0")
    }
    it {
      data[:config][:r] = '3.2'
      should eq("cache-#{CACHE_SLUG_EXTRAS}--R-3.2.5")
    }
    it {
      data[:config][:r] = 'release'
      should eq("cache-#{CACHE_SLUG_EXTRAS}--R-3.3.1")
    }
    it {
      data[:config][:r] = 'oldrel'
      should eq("cache-#{CACHE_SLUG_EXTRAS}--R-3.2.5")
    }
    it {
      data[:config][:r] = '3.1'
      should eq("cache-#{CACHE_SLUG_EXTRAS}--R-3.1.3")
    }
    it {
      data[:config][:r] = 'devel'
      should eq("cache-#{CACHE_SLUG_EXTRAS}--R-devel")
    }
  end
end
