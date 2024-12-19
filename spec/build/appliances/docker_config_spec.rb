require 'spec_helper'

describe Travis::Build::Appliances::DockerConfig, :sexp do
  let(:config)  { PAYLOADS[:worker_config] }
  let(:payload) { payload_for(:push, :ruby, config: { addons: {}, cache: 'bundler'}).merge(config) }
  let(:script)  { Travis::Build.script(payload) }
  let(:code)    { script.compile }
  subject       { script.sexp }

  describe '#apply' do
    context 'use default' do
      before {ENV.delete('TRAVIS_BUILD_DOCKER_BUILDKIT_PROGRESS') }
        it { should include_sexp [:raw, "export BUILDKIT_PROGRESS=plain"] }
    end

    context 'use custom' do
      before {ENV['TRAVIS_BUILD_DOCKER_BUILDKIT_PROGRESS'] = 'tty' }
        it { should include_sexp [:raw, "export BUILDKIT_PROGRESS=tty"] }
    end
  end
end
