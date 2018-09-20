require 'spec_helper'

describe Travis::Build::Addons::Mariadb, :sexp do
  let(:script) { stub('script') }
  let(:config) { '10.0' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { mariadb: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  it { store_example }

  it_behaves_like 'compiled script' do
    let(:cmds) { ["service mysql stop", "service mysql start"] }
  end

  it 'sets TRAVIS_MARIADB_VERSION' do
    should include_sexp [:export,  ['TRAVIS_MARIADB_VERSION', '10.0']]
  end

  it { should include_sexp [:cmd, "service mysql stop", sudo: true] }
  it { should include_sexp [:cmd, "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 #{Travis::Build::Addons::Mariadb::MARIADB_GPG_KEY_OLD}", sudo: true] }
  it { should include_sexp [:cmd, 'add-apt-repository "deb http://%p/mariadb/repo/%p/ubuntu $(lsb_release -cs) main"' % [Travis::Build::Addons::Mariadb::MARIADB_MIRROR, config], sudo: true] }
  it { should include_sexp [:cmd, 'travis_apt_get_update', retry: true, echo: true] }
  it { should include_sexp [:cmd, "PACKAGES='mariadb-server mariadb-server-10.0'", echo: true] }
  it { should include_sexp [:cmd, "apt-get install -y -o Dpkg::Options::='--force-confnew' $PACKAGES", sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, "service mysql start", sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, "mysql --version", echo: true] }
end
