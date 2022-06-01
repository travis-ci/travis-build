require 'spec_helper'

describe Travis::Vcs::Git::Clone, :sexp do
  let(:payload) { payload_for(:push, :ruby) }
  let(:script)  { Travis::Build::Script.new(payload) }
  subject       { script.sexp }

  let(:sexp) { sexp_find(subject, [:if, '-f .gitmodules'], [:then]) }

  let(:no_host_key_check) { [:file, ['~/.ssh/config', "Host github.com\n\tStrictHostKeyChecking no\n"], append: true] }
  let(:submodule_update)  { [:cmd, 'git submodule update --init --recursive', assert: true, echo: true, retry: true, timing: true] }

  describe 'if .gitmodules exists' do
    it { should include_sexp no_host_key_check }

    describe 'if :submodules_depth is not given' do
      it { should include_sexp submodule_update }
    end

    describe 'if :submodules_depth is given' do
      before { payload[:config][:git] = { submodules_depth: 50 } }
      it { should include_sexp [:cmd, 'git submodule update --init --recursive --depth=50', assert: true, echo: true, retry: true, timing: true] }
    end
  end

  describe 'submodules is set to false' do
    before { payload[:config][:git] = { submodules: false } }

    it { expect(sexp_find(subject, submodule_update)).to be_empty }
  end
end
