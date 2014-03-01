require 'json'
require 'sinatra'

require 'travis/build'

before do
  return if ENV['API_TOKEN'].nil? || ENV['API_TOKEN'].empty?

  type, token = env['HTTP_AUTHORIZATION'].to_s.split(' ', 2)

  unless type == 'token' && token == ENV['API_TOKEN']
    halt 403, 'access denied'
  end
end

post '/script' do
  data = JSON.parse(request.body.read)

  content_type :txt
  Travis::Build.script(data, logs: { build: false, state: true }).compile
end
