require 'spec_helper'
require 'travis/api/build/app'

describe Travis::Api::Build::App, :include_sinatra_helpers do
  let(:app) { described_class.new }

  before do
    described_class.instance_eval do
      set :show_exceptions, :after_handler
    end

    Travis::Api::Build::App.any_instance
      .stubs(:api_tokens).returns(%w(the-token the-other-token))
    Travis::Api::Build::App.any_instance
      .stubs(:auth_disabled?).returns(false)
    set_app(app)
  end

  context 'when there is an unexpected error' do
    it 'returns 500' do
      get '/boom'
      expect(last_response.status).to eq(500)
      expect(last_response.body).to match(/:boom:/)
    end
  end

  describe 'POST /script' do
    before :each do
      header('Content-Type', 'application/json')
    end

    context 'with the first token in the list' do
      it 'returns a script' do
        header('Authorization', 'token the-token')
        response = post '/script', {}, input: PAYLOADS[:push].to_json
        expect(response.status).to eq(200)
        expect(response.body).to start_with('#!/bin/bash')
        expect(response.headers['Content-Type']).to eq('application/x-sh')
      end
    end

    context 'with the second token in the list' do
      it 'returns a script' do
        header('Authorization', 'token the-other-token')
        response = post '/script', {}, input: PAYLOADS[:push].to_json
        expect(response.status).to eq(200)
        expect(response.body).to start_with('#!/bin/bash')
      end
    end

    context 'when compression is requested' do
      it 'returns a compressed response' do
        header('Authorization', 'token the-token')
        header('Accept-Encoding', 'gzip, deflate')
        response = post '/script', {}, input: PAYLOADS[:push].to_json
        expect(response.status).to eq(200)
        expect(response.headers).to include('Content-Encoding')
      end
    end

    context 'without an Authorization header' do
      it 'returns 401' do
        response = post '/script', {}, input: PAYLOADS[:push].to_json
        expect(response.status).to be == 401
      end
    end

    context 'without an Authorization header and authorization is disabled' do
      before do
        Travis::Api::Build::App.any_instance
          .stubs(:auth_disabled?).returns(true)
      end
      it 'returns 200' do
        response = post '/script', {}, input: PAYLOADS[:push].to_json
        expect(response.status).to be == 200
      end
    end

    context 'with an incorrect token' do
      it 'returns 403' do
        header('Authorization', 'token not-the-token')
        response = post '/script', {}, input: PAYLOADS[:push].to_json
        expect(response.status).to be == 403
      end
    end

    context 'with invalid json' do
      it 'returns 400' do
        header('Authorization', 'token the-token')
        response = post '/script', {}, input: "{'invalid':'json"
        expect(response.status).to be == 400
      end
    end
  end

  %w(
    /
    /uptime
  ).each do |path|
    describe "GET #{path}" do
      it 'responds 200' do
        header('Authorization', 'token the-token')
        response = get path
        expect(response.status).to eq(200)
      end
    end
  end

  %w(
    /files/nvm.sh
    /empty.txt
  ).each do |path|
    describe "GET #{path}" do
      before :each do
        header('Authorization', 'token the-token')
        get path
      end

      it 'responds 200' do
        expect(last_response.status).to eq(200)
      end

      it 'has a non-generic content type' do
        expect(last_response.headers['Content-Type'])
          .to_not eq('application/octet-stream')
      end
    end
  end
end
