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
      expected = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImV4cCI6NTQwMCwiaWF0IjowfQ.SEfKPH4IxXp3c1FheGVd6poMULkfHRZ9YFMBYpquIFs"
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
      expected1 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImV4cCI6NTQwMCwiaWF0IjowfQ.ZNsODFURduRtDw2IyuC9_fZGF-fb4b4EW_aXZ1ZZHFs"
      subject.should include_sexp [:export, ['MY_ACCESS_KEY_1', expected1]]
      expected2 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImV4cCI6NTQwMCwiaWF0IjowfQ.mmnY9xdgMAR0yTfnIaZMOAB4QE0J1HiT0XBFJGKnLxs"
      subject.should include_sexp [:export, ['MY_ACCESS_KEY_2', expected2]]
    end
  end
end

