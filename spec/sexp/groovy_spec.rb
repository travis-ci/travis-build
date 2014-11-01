require 'spec_helper'

describe Travis::Build::Script::Groovy, :sexp do
  let(:data)   { PAYLOADS[:push].deep_clone }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'a build script sexp'
  it_behaves_like 'a jvm build sexp'
  it_behaves_like 'announces java versions'
end

