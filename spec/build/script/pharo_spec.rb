require 'spec_helper'

describe Travis::Build::Script::Pharo, :sexp do
  let(:data)   { payload_for(:push, :pharo) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=pharo'] }
  end

  describe 'set pharo version' do
    before do
      data[:config][:pharo] = 'stable'
    end

    it 'sets PHARO to correct version' do
      should include_sexp [:export, ['PHARO', 'stable']]
    end
  end

end
