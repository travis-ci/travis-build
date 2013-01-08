require 'spec_helper'

describe Travis::Build::Script::Groovy do
  let(:options) { { logs: { build: true, state: true } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it_behaves_like 'a build script'
  it_behaves_like 'a jvm build'
end
