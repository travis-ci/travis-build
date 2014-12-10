require 'spec_helper'

describe Travis::Build::Addons::Jwt, :sexp do
  let(:script) { stub('script') }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { jwt: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { Time.stubs(:now).returns(Time.mktime(1970,1,1)) }
  before       { addon.before_before_script }

  describe 'jwt token, one secret' do
    let(:config) { 'MY_ACCESS_KEY=987654321' }
    it "should work" do
      subject.should include_sexp [:echo, 'Initializing JWT', ansi: :yellow]
      expected = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImlhdCI6MH0.vHZdjuxQt6CdFmWPEJLAsVbI_KCxbwJVbgT7jaTxkK4"
      subject.should include_sexp [:export, ['MY_ACCESS_KEY', expected]]
    end
  end

  describe 'jwt token, several secrets' do
    let(:config) { {
      secret1: 'MY_ACCESS_KEY_1=123456789',
      secret2: 'MY_ACCESS_KEY_2=ABCDEF'
    } }
    it "should work" do
      subject.should include_sexp [:echo, 'Initializing JWT', ansi: :yellow]
      expected1 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImlhdCI6MH0.iO-I8CNXhQlgw_dL8R9CDaDPplSC3yf9J399Uumn6CE"
      subject.should include_sexp [:export, ['MY_ACCESS_KEY_1', expected1]]
      expected2 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImlhdCI6MH0.p1B9HnYCh-z5Igek5tr_QVPb1zV1ucwcPZNvY039WKg"
      subject.should include_sexp [:export, ['MY_ACCESS_KEY_2', expected2]]
    end
  end
end

