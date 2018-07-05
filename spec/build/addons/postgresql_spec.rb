require 'spec_helper'

describe Travis::Build::Addons::Postgresql, :sexp do
  let(:script) { stub('script') }
  let(:config) { '9.3' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { postgresql: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  it { store_example }

  it_behaves_like 'compiled script' do
    let(:cmds) { ['service postgresql start 9.3'] }
  end

  it { should include_sexp [:export, ['PATH', '/usr/lib/postgresql/9.3/bin:$PATH']] }
  it { should include_sexp [:echo, 'Starting PostgreSQL v9.3', ansi: :yellow] }
  it { should include_sexp [:cmd, 'service postgresql stop', sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, 'cp -rp /var/lib/postgresql/9.3 /var/ramfs/postgresql/9.3', sudo: true] }
  it { should include_sexp [:cmd, 'service postgresql start 9.3', sudo: true, echo: true, timing: true] }
  it { should include_sexp [:cmd, "sudo -u postgres createuser -s -p #{described_class::DEFAULT_PORT} travis &>/dev/null", echo: true, timing: true] }
  it { should include_sexp [:cmd, "sudo -u postgres createuser -s -p #{described_class::DEFAULT_FALLBACK_PORT} travis &>/dev/null", echo: true, timing: true] }
  it { should include_sexp [:cmd, "sudo -u postgres createdb -O travis -p #{described_class::DEFAULT_PORT} travis &>/dev/null", echo: true, timing: true] }
  it { should include_sexp [:cmd, "sudo -u postgres createdb -O travis -p #{described_class::DEFAULT_FALLBACK_PORT} travis &>/dev/null", echo: true, timing: true] }
end
