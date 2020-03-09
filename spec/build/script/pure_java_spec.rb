require 'spec_helper'

describe Travis::Build::Script::PureJava, :sexp do
  let(:data)   { payload_for(:push, :java) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=java'] }
    let(:cmds) { ['gradlew check'] }
  end

  it_behaves_like 'a build script sexp'
  it_behaves_like 'a jvm build sexp'
  it_behaves_like 'announces java versions'
end

