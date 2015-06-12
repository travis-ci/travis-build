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
      expected = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ0cmF2aXMtY2kub3JnIiwic2x1ZyI6InRyYXZpcy1jaS90cmF2aXMtY2kiLCJwdWxsLXJlcXVlc3QiOiIiLCJleHAiOjU0MDAsImlhdCI6MH0.soQJgHR6cGNr9Lj_N6yL2Nk5SQug-hXGUPenJy1QTVc"
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
      expected1 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ0cmF2aXMtY2kub3JnIiwic2x1ZyI6InRyYXZpcy1jaS90cmF2aXMtY2kiLCJwdWxsLXJlcXVlc3QiOiIiLCJleHAiOjU0MDAsImlhdCI6MH0.ISnBTj5MYXAMhvG2P_3JkSCql1Vx1xptlTJMNQsGAPU"
      subject.should include_sexp [:export, ['MY_ACCESS_KEY_1', expected1]]
      expected2 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ0cmF2aXMtY2kub3JnIiwic2x1ZyI6InRyYXZpcy1jaS90cmF2aXMtY2kiLCJwdWxsLXJlcXVlc3QiOiIiLCJleHAiOjU0MDAsImlhdCI6MH0.xC_e3O9-bsNDxI61fFudUUrWyVOeLNN1XFPux_aRRto"
      subject.should include_sexp [:export, ['MY_ACCESS_KEY_2', expected2]]
    end
  end
end

