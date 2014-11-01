require 'spec_helper'

describe Travis::Build::Script::Addons::Postgresql, :sexp do
  let(:config)  { '9.3' }
  let(:data)    { PAYLOADS[:push].deep_clone }
  let(:sh)      { Travis::Shell::Builder.new }
  let(:addon)   { described_class.new(sh, Travis::Build::Data.new(data), config) }
  subject       { sh.to_sexp }
  before        { addon.before_prepare }

  it { should include_sexp [:export, ['PATH', '/usr/lib/postgresql/9.3/bin:$PATH']] }
  it { should include_sexp [:echo, 'Starting PostgreSQL v9.3', ansi: :yellow] }
  it { should include_sexp [:cmd, 'service postgresql stop', sudo: true] }
  it { should include_sexp [:cmd, 'service postgresql start 9.3', sudo: true] }
end
