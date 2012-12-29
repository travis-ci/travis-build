require 'spec_helper'

describe Travis::Build::Script::Groovy do
  let(:data) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data).compile }

  it_behaves_like 'a build script'
  it_behaves_like 'a jvm build'
end
