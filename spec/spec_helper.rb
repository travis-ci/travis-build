require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'mocha'

require 'travis/build'
include Travis

RSpec.configure do |config|
  config.mock_with :mocha
end
