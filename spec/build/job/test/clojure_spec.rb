require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Clojure do
  let(:config) { Travis::Build::Job::Test::Clojure::Config.new }

  describe 'config' do
    it 'defaults :install to "lein deps"' do
      config.install.should == 'lein deps'
    end

    it 'defaults :script to "lein test"' do
      config.script.should == 'lein test'
    end
  end
end
