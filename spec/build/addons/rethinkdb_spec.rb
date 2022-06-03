require 'spec_helper'

describe Travis::Build::Addons::Rethinkdb, :sexp do
  let(:script) { stub('script') }
  let(:config) { '2.3.4' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { rethinkdb: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  it { store_example }

  it_behaves_like 'compiled script' do
    let(:cmds) { ["service rethinkdb stop", "service rethinkdb start"] }
  end

  it 'sets TRAVIS_RETHINKDB_VERSION' do
    should include_sexp [:export,  ['TRAVIS_RETHINKDB_VERSION', '2.3.4']]
  end

  it 'sets TRAVIS_RETHINKDB_PACKAGE_VERSION' do
    should include_sexp [:export,  ['TRAVIS_RETHINKDB_PACKAGE_VERSION', '$package_version']]
  end

  it { should include_sexp [:cmd, "service rethinkdb stop", sudo: true] }
  it { should include_sexp [:cmd, "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \"539A 3A8C 6692 E6E3 F69B 3FE8 1D85 E93F 801B B43F\"", echo: true] }
  it { should include_sexp [:cmd, 'echo -e "\ndeb https://download.rethinkdb.com/repository/ubuntu-$(lsb_release -cs)/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/rethinkdb.list > /dev/null'] }
  it { should include_sexp [:cmd, 'travis_apt_get_update'] }
  it { should include_sexp [:cmd, "apt-get install -y -o Dpkg::Options::='--force-confnew' rethinkdb=$package_version", sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, "cp /etc/rethinkdb/default.conf.sample /etc/rethinkdb/instances.d/default.conf", sudo: true] }
  it { should include_sexp [:cmd, "service rethinkdb start", sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, "rethinkdb --version", echo: true] }
end
