# vim:set ts=2 sw=2 sts=2 autoindent:

require 'spec_helper'

describe Travis::Build::Script::Dart, :sexp do
  let(:data)   { payload_for(:push, :dart) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_DART_VERSION' do
    should include_sexp [:export, ['TRAVIS_DART_VERSION', 'stable']]
  end

  it 'sets DART_SDK' do
    should include_sexp [:cmd, %r(export DART_SDK=.*), assert: true,
      echo: true, timing: true]
  end

  it "announces `dart --version`" do
    should include_sexp [:cmd, "dart --version", echo: true]
  end
end
