require 'spec_helper'

describe Travis::Build::Script::Haxe, :sexp do
  let(:data)   { payload_for(:push, :haxe) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'
  it_behaves_like 'a build script sexp'

  it 'downloads and installs haxe' do
    should include_sexp [:cmd, %r(curl .*haxe.*\.tar\.gz),
                         assert: true, echo: true, timing: true]
  end

  it 'downloads and installs neko' do
    should include_sexp [:cmd, %r(curl .*neko.*\.tar\.gz),
                         assert: true, echo: true, timing: true]
  end

  it 'announces haxe -version' do
    should include_sexp [:cmd, /haxe -version/, echo: true]
  end

  it 'announces neko -version' do
    should include_sexp [:cmd, /neko -version/, echo: true]
  end
end
