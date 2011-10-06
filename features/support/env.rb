root = File.expand_path('../../..', __FILE__)

$: << "#{root}/lib" << "#{root}/spec"

require 'travis/build'
require 'mocha'
require 'support/mocks'
require 'support/payloads'

World(Mocha::API)

Before do
  mocha_setup
end

After do
  begin
    mocha_verify
  ensure
    mocha_teardown
  end
end
