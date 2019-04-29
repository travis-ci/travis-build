require 'spec_helper'

describe Travis::Build::Git, :sexp do
  let(:payload) { payload_for(:push, :ruby) }
  let(:script)  { Travis::Build::Script.new(payload) }
  subject       { script.sexp }

  let(:rm_ssh_key)    { [:rm, '~/.ssh/source_rsa', force: true] }

  it { should include_sexp rm_ssh_key }
end
