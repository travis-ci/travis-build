require 'spec_helper'

describe Travis::Build::Addons::Postgresql, :sexp do
  let(:script) { stub('script') }
  let(:config) { '9.5' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { postgresql: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  it { store_example }

  it_behaves_like 'compiled script' do
    let(:cmds) { ['service postgresql start 9.5'] }
  end

  it { should include_sexp [:export, ['PATH', '/usr/lib/postgresql/9.5/bin:$PATH']] }
  it { should include_sexp [:echo, 'Starting PostgreSQL v9.5', ansi: :yellow] }
  it { should include_sexp [:cmd, 'service postgresql stop', sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, 'cp -rp /var/lib/postgresql/9.5 /var/ramfs/postgresql/9.5', sudo: true] }
  it { should include_sexp [:cmd, 'service postgresql start 9.5', sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, "sudo -u postgres createuser -p #{described_class::DEFAULT_PORT} travis &>/dev/null", echo: true, timing: true] }
  it { should include_sexp [:cmd, "sudo -u postgres createuser -p #{described_class::DEFAULT_FALLBACK_PORT} travis &>/dev/null", echo: true, timing: true] }
  it { should include_sexp [:cmd, "sudo -u postgres createdb -p #{described_class::DEFAULT_PORT} travis &>/dev/null", echo: true, timing: true] }
  it { should include_sexp [:cmd, "sudo -u postgres createdb -p #{described_class::DEFAULT_FALLBACK_PORT} travis &>/dev/null", echo: true, timing: true] }
end
