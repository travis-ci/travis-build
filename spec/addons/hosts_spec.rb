require "spec_helper"

describe Travis::Build::Script::Addons::Hosts, :sexp do
  let(:config)  { 'one.local two.local' }
  let(:sh)      { Travis::Shell::Builder.new }
  let(:addon)   { described_class.new(sh, nil, config) }
  subject       { sh.to_sexp }
  before(:each) { addon.after_pre_setup }

  it { should include_sexp [:cmd, "sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 'one.local\\ two.local'/' -i'.bak' /etc/hosts", sudo: true] }
  it { should include_sexp [:cmd, "sed -e 's/^\\(::1.*\\)$/\\1 'one.local\\ two.local'/' -i'.bak' /etc/hosts", sudo: true] }
end

