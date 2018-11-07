# vim:set ts=2 sw=2 sts=2 autoindent:

require 'spec_helper'

describe Travis::Build::Script::Julia, :sexp do
  let(:data)   { payload_for(:push, :julia) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'
  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_JULIA_VERSION' do
    should include_sexp [:export, ['TRAVIS_JULIA_VERSION', 'release']]
  end

  it 'downloads and installs Julia' do
    should include_sexp [:cmd, %r(curl .*latest-linux-x86_64), assert: true,
      echo: true, timing: true]
  end

end
