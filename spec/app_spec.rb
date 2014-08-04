require "spec_helper"
require "travis/build/app"

describe Travis::Build::App, :include_sinatra_helpers do
  before do
    set_app Travis::Build::App.new
    ENV["API_TOKEN"] = "the-token"
    header("Content-Type", "application/json")
  end

  describe "/script" do
    context "with the right token" do
      it "returns a script" do
        header("Authorization", "token the-token")
        response = post "/script", {}, input: PAYLOADS[:push].to_json
        expect(response.body).to start_with("#!/bin/bash")
      end
    end

    context "without a token" do
      it "returns 403" do
        response = post "/script", {}, input: PAYLOADS[:push].to_json
        expect(response.status).to be == 403
      end
    end

    context "with an incorrect token" do
      it "returns 403" do
        header("Authorization", "token not-the-token")
        response = post "/script", {}, input: PAYLOADS[:push].to_json
        expect(response.status).to be == 403
      end
    end

    context "with invalid json" do
      it "returns 400" do
        header("Authorization", "token the-token")
        response = post "/script", {}, input: "{'invalid':'json"
        expect(response.status).to be == 400
      end
    end
  end

  describe "/uptime" do
    context "without a token" do
      it "returns 204" do
        response = get "/uptime"
        expect(response.status).to be == 204
      end
    end
  end
end
