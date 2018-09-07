require 'spec_helper'

describe Travis::Build::Addons::Postgresql, :sexp do
  let(:script) { stub('script') }
  let(:config) { '9.3' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { postgresql: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }

  before do
    script.stubs(bash: '# (bash here)')
    addon.after_prepare
  end

  it { store_example }

  it_behaves_like 'compiled script' do
    let(:code) { [
      'service postgresql start ${version}',
      'systemctl start postgresql@${version}-main',
      'sudo -u postgres createuser -s -p "${port}" travis',
      'sudo -u postgres createdb -O travis -p "${port}" travis',
      'export PATH="/usr/lib/postgresql/${version}/bin:$PATH"',
      'cp -rp \"/var/lib/postgresql/${version}\" \"/var/ramfs/postgresql/${version}\"'
    ] }
  end

  it { should include_sexp [:cmd, "travis_setup_postgresql #{config}", echo: true, timing: true] }
end
