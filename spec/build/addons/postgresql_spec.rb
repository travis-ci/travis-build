require 'spec_helper'

describe Travis::Build::Addons::Postgresql, :sexp do
  let(:script) { stub('script') }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { postgresql: config }, dist: dist, os: os }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  context 'for dist: trusty' do
    let(:config) { '9.3' }
    let(:dist)   { 'trusty' }
    let(:os)     { 'linux' }

    it { store_example }

    it_behaves_like 'compiled script' do
      let(:cmds) { ["service postgresql start #{config}"] }
    end

    it { should include_sexp [:export, ['PATH', "/usr/lib/postgresql/#{config}/bin:$PATH"]] }
    it { should include_sexp [:echo, "Starting PostgreSQL v#{config}", ansi: :yellow] }
    it { should include_sexp [:cmd, "cp -rp /var/lib/postgresql/#{config} /var/ramfs/postgresql/#{config}", sudo: true] }
    it { should include_sexp [:cmd, "sudo -u postgres createuser -s -p #{described_class::DEFAULT_PORT} travis &>/dev/null", echo: true, timing: true] }
    it { should include_sexp [:cmd, "sudo -u postgres createuser -s -p #{described_class::DEFAULT_FALLBACK_PORT} travis &>/dev/null", echo: true, timing: true] }
    it { should include_sexp [:cmd, "sudo -u postgres createdb -O travis -p #{described_class::DEFAULT_PORT} travis &>/dev/null", echo: true, timing: true] }
    it { should include_sexp [:cmd, "sudo -u postgres createdb -O travis -p #{described_class::DEFAULT_FALLBACK_PORT} travis &>/dev/null", echo: true, timing: true] }

    it { should include_sexp [:cmd, 'service postgresql stop', sudo: true, echo: true, timing: true] }
    it { should include_sexp [:cmd, "service postgresql start #{config}", sudo: true, echo: true, timing: true] }
  end

  context 'for dist: xenial' do
    let(:config) { '10' }
    let(:dist)   { 'xenial' }
    let(:os)     { 'linux' }

    it_behaves_like 'compiled script' do
      let(:cmds) { ["systemctl start postgresql@#{config}-main"] }
    end

    it { should include_sexp [:export, ['PATH', "/usr/lib/postgresql/#{config}/bin:$PATH"]] }
    it { should include_sexp [:echo, "Starting PostgreSQL v#{config}", ansi: :yellow] }
    it { should include_sexp [:cmd, "cp -rp /var/lib/postgresql/#{config} /var/ramfs/postgresql/#{config}", sudo: true] }
    it { should include_sexp [:cmd, "sudo -u postgres createuser -s -p #{described_class::DEFAULT_PORT} travis &>/dev/null", echo: true, timing: true] }
    it { should include_sexp [:cmd, "sudo -u postgres createuser -s -p #{described_class::DEFAULT_FALLBACK_PORT} travis &>/dev/null", echo: true, timing: true] }
    it { should include_sexp [:cmd, "sudo -u postgres createdb -O travis -p #{described_class::DEFAULT_PORT} travis &>/dev/null", echo: true, timing: true] }
    it { should include_sexp [:cmd, "sudo -u postgres createdb -O travis -p #{described_class::DEFAULT_FALLBACK_PORT} travis &>/dev/null", echo: true, timing: true] }

    it { should include_sexp [:cmd, 'systemctl stop postgresql', sudo: true, echo: true, timing: true] }
    it { should include_sexp [:cmd, "systemctl start postgresql@#{config}-main", sudo: true, echo: true, timing: true] }
  end

  context 'for os: osx' do
    let(:os) { 'osx' }
    let(:config) { '9.6' }
    let(:dist) { 'irrelevant' }

    it { should include_sexp [:echo, "Addon PostgreSQL is not supported on #{os}", ansi: :red] }
    it { should_not include_sexp [:echo, "Starting PostgreSQL v#{config}", ansi: :yellow] }
  end
end
