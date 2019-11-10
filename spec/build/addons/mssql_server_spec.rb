require 'spec_helper'

describe Travis::Build::Addons::MssqlServer, :sexp do
  let(:script) { stub('script') }
  let(:config) { '2017' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { mssql_server: config } }) }
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
      "ubuntu_version='16.04'",
      'sudo env ACCEPT_EULA=Y apt-get install -y mssql-server',
      'sudo env ACCEPT_EULA=Y apt install -y msodbcsql17',
      'sudo env ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev',
      'sudo env MSSQL_SA_PASSWORD="Password1!" /opt/mssql/bin/mssql-conf -n setup accept-eula',
      'systemctl status mssql-server --no-pager'
    ] }
  end

  it { should include_sexp [:cmd, "travis_setup_mssql_server #{config}", echo: true, timing: true] }
end
