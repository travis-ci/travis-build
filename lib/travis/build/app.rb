require 'json'
require 'sinatra'

require 'travis/build'

post '/script' do
  data = JSON.parse(request.body.read)

  content_type :txt
  Travis::Build.script(data, logs: { build: false, state: true }).compile
end
