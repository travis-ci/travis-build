require 'spec_helper'

describe Travis::Build::Script do
  let(:data) do
    PAYLOADS[:push].deep_clone.tap do |d|
      d['config']['services'] = services
    end
  end

  let(:services) { [] }

  subject { described_class.new(data).compile }

  after :all do
    store_example
  end

  Travis::Build::Script::Services::MAP.each do |service_alias, service|
    describe "when #{service_alias} is in services" do
      let(:services) { [service_alias] }

      it "starts #{service}" do
        is_expected.to travis_cmd "sudo service #{service} start", assert: false
      end

      it "announces #{service} version" do
        is_expected.to travis_cmd Travis::Build::Script::Services::VERSION_COMMANDS[service], assert: false
      end
    end
  end

  %w[couchdb elasticsearch mongodb mysql postgresql riak].each do |service|
    describe "when #{service} is in services" do
      let(:services) { [service] }

      it "starts #{service}" do
        is_expected.to travis_cmd "sudo service #{service} start", assert: false
      end

      it "announces #{service} version" do
        is_expected.to travis_cmd Travis::Build::Script::Services::VERSION_COMMANDS[service], assert: false
      end
    end
  end
end
