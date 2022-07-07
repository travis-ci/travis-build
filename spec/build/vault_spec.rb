require 'spec_helper'

describe "integration vault tests" do
  before do
    stub_request(:get, 'https://myvault.org/v1/secret/your/aaa/bbb').
      with(headers: {  'X-Vault-Token': 'hvs.Pgfcl9Nr0AozXCLQF5Wtb6FSD' }).
      to_return(status: 200, body: { data: { my_data: { b: '123' } } }.to_json)

    stub_request(:get, 'https://myvault.org/v1/secret/my/x-something').
      with(headers: {  'X-Vault-Token': 'hvs.Pgfcl9Nr0AozXCLQF5Wtb6FSD' }).
      to_return(status: 404, body: '<html></html>')

    stub_request(:get, 'https://myvault.org/v1/secret/data/your/aaa/bbb').
      with(headers: {  'X-Vault-Token': 'hvs.Pgfcl9Nr0AozXCLQF5Wtb6FSD' }).
      to_return(status: 200, body: { data: { my_data: { b: '123' } } }.to_json)

    stub_request(:get, 'https://myvault.org/v1/secret/data/my/x-something').
      with(headers: {  'X-Vault-Token': 'hvs.Pgfcl9Nr0AozXCLQF5Wtb6FSD' }).
      to_return(status: 404, body: '<html></html>')
  end

  context 'when authenticated' do
    before do
      stub_request(:get, "https://myvault.org/v1/auth/token/lookup-self").
        with(
          headers: {
             'X-Vault-Token': 'hvs.Pgfcl9Nr0AozXCLQF5Wtb6FSD'
          }).
        to_return(status: 200, body: "", headers: {})
    end

    %w[kv1 kv2].each do |version|
      it do
        expect do
          Travis::Build::Script.new(JSON.parse(File.read("#{Dir.pwd}/spec/fixtures/build_config_with_vault_#{version}.json"))).sexp
        end.not_to raise_error
      end
    end
  end

  context 'when not authenticated' do
    before do
      stub_request(:get, "https://myvault.org/v1/auth/token/lookup-self").
        with(
          headers: {
             'X-Vault-Token': 'hvs.Pgfcl9Nr0AozXCLQF5Wtb6FSD'
          }).
        to_return(status: 404, body: "", headers: {})
    end

    %w[kv1 kv2].each do |version|
      it do
        expect do
          Travis::Build::Script.new(JSON.parse(File.read("#{Dir.pwd}/spec/fixtures/build_config_with_vault_#{version}.json"))).sexp
        end.not_to raise_error
      end
    end
  end
end
