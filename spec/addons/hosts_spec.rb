require "spec_helper"

describe Travis::Build::Script::Addons::Hosts, :sexp do
  let(:config)  { 'one.local two.local' }
  let(:data)    { PAYLOADS[:push].deep_clone }
  let(:sh)      { Travis::Shell::Builder.new }
  let(:addon)   { described_class.new(sh, Travis::Build::Data.new(data), config) }
  subject       { sh.to_sexp }
  before        { addon.after_pre_setup }

  it { should include_sexp [:cmd, "sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 'one.local\\ two.local'/' -i'.bak' /etc/hosts", sudo: true] }
  it { should include_sexp [:cmd, "sed -e 's/^\\(::1.*\\)$/\\1 'one.local\\ two.local'/' -i'.bak' /etc/hosts", sudo: true] }
end

