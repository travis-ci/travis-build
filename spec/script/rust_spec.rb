require "spec_helper"

describe Travis::Build::Script::Rust do
  let(:data) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, {}).compile }

  after(:all) do
    store_example
  end

  it_behaves_like "a build script"

  # it "downloads and installs Rust" do
  #   is_expected.to setup(/tar.+~\/rust/)
  # end
  #
  # it "downloads and installs Cargo" do
  #   is_expected.to setup(/tar.+~\/rust/)
  # end

  it "runs cargo build" do
    is_expected.to travis_cmd("cargo build")
  end

  it "runs cargo test" do
    is_expected.to travis_cmd("cargo test")
  end
end
