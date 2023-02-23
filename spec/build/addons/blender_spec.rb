require 'spec_helper'

describe Travis::Build::Addons::Blender, :sexp do
  let(:script) { stub('script') }
  let(:config) { '10.0' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { blender: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  context 'when version is invalid' do
    let(:config) { '2.112323' }

    it do
      should include_sexp [:echo, "Blender: Invalid version '2.112323' given. Valid versions are: 3.4.1", { ansi: :red }]
    end
  end

  context 'when version is valid' do
    let(:config) { '3.4.1' }

    it { should include_sexp [:echo, 'Installing Blender version: 3.4.1', { ansi: :yellow }] }
    it { should include_sexp [:cmd, 'curl https://ftp.halifax.rwth-aachen.de/blender/release/Blender3.4/blender-3.4.1-linux-x64.tar.xz --output blender-3.4.1-linux-x64.tar.xz'] }
    it { should include_sexp [:cmd, 'tar -xf blender-3.4.1-linux-x64.tar'] }
    it { should include_sexp [:cmd, 'alias blender=$(pwd)/blender-3.4.1-linux-x64/blender'] }
  end
end
