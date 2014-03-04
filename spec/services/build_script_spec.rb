require 'spec_helper'
require 'travis/testing/stubs'

describe Travis::Build::Services::BuildScript do
  include Travis::Testing::Stubs

  let(:service) { Travis.service(:build_script, id: test.id) }

  before :each do
    service.stubs(:run_service).with(:find_job, id: test.id).returns(test)
  end

  it 'generates the build script for the given job' do
    service.run.should include('travis_start')
  end
end
