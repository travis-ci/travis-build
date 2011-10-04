require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'mocha'

require 'travis/build'
include Travis::Build

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| load f }

RSpec.configure do |config|
  config.mock_with :mocha
end
