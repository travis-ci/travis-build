require 'spec_helper'

describe Travis::Build::Script::PureJava, :sexp do
  # after(:all) { store_example }
  let(:data) { PAYLOADS[:push].deep_clone }
  subject { described_class.new(data).sexp }

  it_behaves_like 'a build script sexp'
  it_behaves_like 'a jvm build sexp'
end

