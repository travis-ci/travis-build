require 'spec_helper'

describe Travis::Build::Script, :sexp do
  let(:data)   { payload_for(:push, :android) }
  let(:script) { described_class.new(data) }
  let(:sexp)   { script.sexp }
  let(:code)   { script.compile }

  it 'uses $HOME/build as a working directory' do
    expect(code).to match %r(cd +\$HOME/build)
  end

  describe 'does not exlode' do
    it 'on script being true' do
      data[:config][:script] = true
      expect { sexp }.to_not raise_error
    end
  end
end
