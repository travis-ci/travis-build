require 'spec_helper'

describe Travis::Build::Addons::Jwt, :sexp do
  let(:script) { stub('script') }
  let(:data)   { payload_for(:push, config: { language: 'ruby', addons: { jwt: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { Time.stubs(:now).returns(Time.at(28800)) }
  before       { addon.before_before_install }

  describe 'jwt token' do
    describe 'one secret' do
      let(:config) { ['MY_ACCESS_KEY=987654321'] }
      it "should work" do
        expect(subject).to include_sexp [:echo, 'Initializing JWT', ansi: :yellow]
        expected = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJUcmF2aXMgQ0ksIEdtYkgiLCJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImV4cCI6MzQyMDAsImlhdCI6Mjg4MDB9.xFz1U8eEulqkvy_odV0hxDbMLmaeZWgIuM7Oj-NWQ-0"
        expect(subject).to include_sexp [:export, ['MY_ACCESS_KEY', expected]]
      end
    end

    describe 'several secrets' do
      let(:config) { [
        'MY_ACCESS_KEY_3=123456789',
        'MY_ACCESS_KEY_4=ABCDEF'
      ] }
      it "should work" do
        expect(subject).to include_sexp [:echo, 'Initializing JWT', ansi: :yellow]
        expected1 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJUcmF2aXMgQ0ksIEdtYkgiLCJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImV4cCI6MzQyMDAsImlhdCI6Mjg4MDB9.LHFaZc1YZATFKCmZv9f-7FYyA_jdE3Toh48iTDz2m1o"
        expect(subject).to include_sexp [:export, ['MY_ACCESS_KEY_3', expected1]]
        expected2 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJUcmF2aXMgQ0ksIEdtYkgiLCJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImV4cCI6MzQyMDAsImlhdCI6Mjg4MDB9.e2m4CvKHVJn_UjiZL2BkKF45VVC0IgAeW5FaEhH2gWM"
        expect(subject).to include_sexp [:export, ['MY_ACCESS_KEY_4', expected2]]
      end
    end

    describe 'handle raising an exception on 100%' do
      let(:config) { ["JUSTKEY"]; }

      it "should output warning about bad data" do
        expect(subject).to include_sexp [:echo, "There was an error while encoding JWT. If the secret is encrypted, ensure that it is encrypted correctly.", {:ansi=>:yellow}]
      end
    end

    describe 'handle raising an exception on 50%' do
      let(:config) { ["JUSTKEY", 'BAD_ACCESS_KEY=abc123']; }

      it "should output warning about bad data" do
        # first one throws an exception
        expect(subject).to include_sexp [:echo, "There was an error while encoding JWT. If the secret is encrypted, ensure that it is encrypted correctly.", {:ansi=>:yellow}]
      end

      it "should also handle second variable" do
        expect(subject).to include_sexp [:echo, 'Initializing JWT', ansi: :yellow]
        # second one passes
        expected = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJUcmF2aXMgQ0ksIEdtYkgiLCJzbHVnIjoidHJhdmlzLWNpL3RyYXZpcy1jaSIsInB1bGwtcmVxdWVzdCI6IiIsImV4cCI6MzQyMDAsImlhdCI6Mjg4MDB9.Bvl3I1mHgABi6KAs5GFgtoyzj4qZR4xRkF-79bloadg"
        expect(subject).to include_sexp [:export, ['BAD_ACCESS_KEY', expected]]
      end
    end
  end
end

