require 'rubygems'

require 'rspec'
require 'mocha'

require 'logger'
require 'stringio'
require 'travis/support'

require 'support/helpers'
require 'support/matchers'
require 'support/mocks'
require 'support/payloads'

RSpec.configure do |config|
  config.mock_with :mocha

  config.before :each do
    Travis.logger = Logger.new(StringIO.new)
  end

  config.alias_example_to :fit, :focused => true
  config.filter_run :focused => true
  config.run_all_when_everything_filtered = true
end
