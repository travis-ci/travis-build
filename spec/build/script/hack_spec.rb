require 'spec_helper'

describe Travis::Build::Script::Hack, :sexp do
  let(:data)     { payload_for(:push, :hack) }
  let(:script)   { described_class.new(data) }
  subject(:sexp) { script.sexp }
  it             { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=hack'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_HACK_VERSION' do
    should include_sexp [:export, ['TRAVIS_HACK_VERSION', 'hhvm']]
  end

  context 'with empty hack value' do
    it "installs default hhvm" do
      should include_sexp [:cmd, 'sudo apt-get install hhvm -y 2>&1 >/dev/null', assert: true, timing: true, echo: true]
    end
  end

  HHVM_NUMERIC_VERSIONS = [
    nil,
    'hhvm',
    'hhvm-3.15',
    '3.15'
  ]

  HHVM_NUMERIC_VERSIONS.each do |ver|
    context "with HHVM version #{ver}" do
      before { data[:config][:hhvm] = ver }
      it "installs given hhvm #{ver}" do
        store_example name: ver
        should include_sexp [:cmd, "echo \"deb [ arch=amd64 ] http://dl.hhvm.com/ubuntu $(lsb_release -sc) main\" | sudo tee -a /etc/apt/sources.list >&/dev/null" ]
        should include_sexp [:cmd, "sudo apt-get install hhvm -y 2>&1 >/dev/null", assert: true, timing: true, echo: true]
      end
    end
  end

  HHVM_SPECIAL_NAMES = %w(
    hhvm-nightly
    hhvm-dbg
  )

  HHVM_SPECIAL_NAMES.each do |ver|
    context "with HHVM version #{ver}" do
      before { data[:config][:hhvm] = ver }
      it "installs given hhvm #{ver}" do
        store_example name: ver
        should include_sexp [:cmd, "echo \"deb [ arch=amd64 ] http://dl.hhvm.com/ubuntu $(lsb_release -sc) main\" | sudo tee -a /etc/apt/sources.list >&/dev/null" ]
        should include_sexp [:cmd, "sudo apt-get install #{ver} -y 2>&1 >/dev/null", assert: true, timing: true, echo: true]
      end
    end
  end

  HHVM_LTS_VERSIONS = %w(
    hhvm-4.12-lts
  )

  HHVM_LTS_VERSIONS.each do |ver|
    context "with HHVM LTS version #{ver}" do
      before { data[:config][:hhvm] = ver }
      it "installs given hhvm #{ver}" do
        md = Travis::Build::Script::Hack::HHVM_VERSION_REGEXP.match(ver)
        hhvm_version = md[:num]
        store_example name: ver
        should include_sexp [:cmd, "echo \"deb [ arch=amd64 ] http://dl.hhvm.com/ubuntu $(lsb_release -sc)-lts-#{hhvm_version} main\" | sudo tee -a /etc/apt/sources.list >&/dev/null" ]
        should include_sexp [:cmd, "sudo apt-get install hhvm -y 2>&1 >/dev/null", assert: true, timing: true, echo: true]
      end
    end
  end

  UNRECOGNIZED_VERSIONS = %w(
    foo
    hhvm-bar
  )

  UNRECOGNIZED_VERSIONS.each do |ver|
    context "with HHVM LTS version #{ver}" do
      before { data[:config][:hhvm] = ver }

      it 'warns and does not install hhvm' do
        should include_sexp [:echo, /^Unsupported hhvm version given/]
        should_not include_sexp [:cmd, "sudo apt-get install hhvm -y 2>&1 >/dev/null", assert: true, timing: true, echo: true]
      end
    end
  end
end
