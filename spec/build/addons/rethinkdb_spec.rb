require 'spec_helper'

describe Travis::Build::Addons::Rethinkdb, :sexp do
  let(:script) { stub('script') }
  let(:config) { '2.4.2' }
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
    should include_sexp [:export,  ['TRAVIS_RETHINKDB_VERSION', '2.4.2']]
  end

  it 'sets TRAVIS_RETHINKDB_PACKAGE_VERSION' do
    should include_sexp [:export,  ['TRAVIS_RETHINKDB_PACKAGE_VERSION', '$package_version']]
  end

  it { should include_sexp [:cmd, "service rethinkdb stop", sudo: true] }
  it { should include_sexp [:cmd, "wget -qO- https://download.rethinkdb.com/apt/pubkey.gpg | sudo apt-key add -v -''", echo: true] }
  it { should include_sexp [:cmd, 'echo -e "\ndeb http://download.rethinkdb.com/apt $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list > /dev/null'] }
  it { should include_sexp [:cmd, 'travis_apt_get_update'] }
  it { should include_sexp [:cmd, "apt-get install -y -o Dpkg::Options::='--force-confnew' rethinkdb=$package_version", sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, "cp /etc/rethinkdb/default.conf.sample /etc/rethinkdb/instances.d/default.conf", sudo: true] }
  it { should include_sexp [:cmd, "service rethinkdb start", sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, "rethinkdb --version", echo: true] }
end
