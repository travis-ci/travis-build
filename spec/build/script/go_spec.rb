require 'spec_helper'

xdescribe Travis::Build::Script::Go, :sexp do #requires test image update
  let(:data)     { payload_for(:push, :go) }
  let(:script)   { described_class.new(data) }
  let(:defaults) { described_class::DEFAULTS }

  let(:go_import_path) { 'github.com/travis-ci-examples/go-example' }

  subject        { script.sexp }
  it             { store_example }
  it             { store_example(integration: true) }

  it_behaves_like 'a bash script', integration: true do
    let(:bash_script_file) { bash_script_path(integration: true) }
  end

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=go'] }
    let(:code) { ['go test'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets the default go version if no :go config given' do
    should include_sexp([
      :cmd, %[travis_export_go #{defaults[:go]} #{go_import_path}],
      echo: true
    ])
  end

  it 'sets the go version from config :go' do
    data[:config][:go] = 'go1.22.5'
    should include_sexp([
      :cmd, %[travis_export_go 1.22.5 #{go_import_path}],
      echo: true
    ])
  end

  it 'installs the go version' do
    data[:config][:go] = 'go1.22'
    should include_sexp([
      :cmd, %[travis_export_go 1.22 #{go_import_path}],
      echo: true
    ])
  end

  context 'when go version is an array' do
    it 'installs the first version specified' do
      data[:config][:go] = ['1.16']

      should include_sexp([
        :cmd, %[travis_export_go 1.16 #{go_import_path}],
        echo: true
      ])
    end
  end

  it 'announces go version' do
    should include_sexp [:cmd, 'go version', echo: true]
  end

  it 'announces go env' do
    should include_sexp [:cmd, 'go env', echo: true]
  end
end
