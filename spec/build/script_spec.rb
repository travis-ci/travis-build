require 'spec_helper'

describe Travis::Build::Script, :sexp do
  let(:config)   { PAYLOADS[:worker_config] }
  let(:payload)  { payload_for(:push, :ruby, config: { services: ['redis'], cache: ['apt', 'bundler'] }).merge(config) }
  let(:script)   { Travis::Build.script(payload) }
  let(:code)     { script.compile }
  subject(:sexp) { script.sexp }

  it 'uses $HOME/build as a working directory' do
    expect(code).to match %r(cd +\$HOME/build)
  end

  it 'runs stages in the expected order' do
    expected = [
      :before_header, :header, :after_header,
      :before_configure, :configure, :after_configure,
      :before_checkout, :checkout, :after_checkout,
      :before_export, :export, :after_export,
      :before_setup, :setup, :after_setup,
      :before_announce, :announce, :after_announce,
      :before_before_install, :before_install, :after_before_install,
      :before_install, :install, :after_install,
      :before_before_script, :before_script, :after_before_script,
      :before_script, :script, :after_script,
      :before_after_script, :after_script, :after_after_script,
      :before_finish, :finish, :after_finish,
      :deploy
    ]
    actual = sexp_filter(subject, [:group]).map { |group| group[1] }
    expect(actual).to eq expected
  end

  describe 'configure' do
    subject { sexp_find(sexp, [:group, :configure]) }

    it 'applies resolv.conf fix' do
      should include_sexp [:raw, %r(tee /etc/resolv.conf)]
    end

    it 'applies /etc/hosts fix' do
      should include_sexp [:raw, %r(sed .* /etc/hosts)]
    end

    it 'starts services' do
      should include_sexp [:cmd, %r(service redis-server start), :*]
    end

    it 'sets up apt cache' do
      should include_sexp [:cmd, %r(tee /etc/apt/apt.conf.d/01proxy)]
    end

    it 'applies PS4 fix' do
      should include_sexp [:export, ['PS4', '+']]
    end

    it 'disables sudo' do
      should include_sexp [:cmd, %r(rm -f /etc/sudoers.d/travis)]
    end
  end

  it 'runs casher fetch' do
    should include_sexp [:cmd, /casher fetch/, :*]
  end

  it 'runs casher push' do
    should include_sexp [:cmd, /casher push/, :*]
  end

  describe 'does not exlode' do
    it 'on script being true' do
      payload[:config][:script] = true
      expect { subject }.to_not raise_error
    end
  end
end
