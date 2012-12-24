require 'spec_helper'

describe Travis::Build::Script::PureJava do
  let(:config) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(config).compile }

  it_behaves_like 'a build script'
  it_behaves_like 'a jvm build'
end
