require 'spec_helper'

describe Travis::Build::Script::Csharp, :sexp do
  let(:data)    { payload_for(:push, :csharp) }
  let(:script) { described_class.new(data) }
  subject { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=csharp'] }
  end

  it_behaves_like 'a build script sexp'

  describe 'configure' do
    it 'sets up package repository' do
      should include_sexp [:cmd, 'sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF', assert: true]
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", assert: true]
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy-libtiff-compat main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", assert: true]
      should include_sexp [:cmd, 'sudo apt-get update -qq', timing: true, assert: true]
    end

    it 'installs mono' do
      should include_sexp [:cmd, 'sudo apt-get install -qq mono-complete mono-vbnc fsharp nuget referenceassemblies-pcl', timing: true, assert: true]
      should include_sexp [:cmd, 'mozroots --import --sync --quiet', timing: true]
    end
  end

  describe 'version switching' do
    it 'throws a error with a invalid version' do
      data[:config][:mono] = 'foo'
      should include_sexp [:echo, '"foo" is not a valid version of mono.', {:ansi=>:red}]
    end

    it 'throws a error with a invalid version' do
      data[:config][:mono] = '12.55.523'
      should include_sexp [:echo, '"12.55.523" is not a valid version of mono.', {:ansi=>:red}]
    end

    it 'throws a error for invalid version of mono 2' do
      data[:config][:mono] = '2.1.1'
      should include_sexp [:echo, '"2.1.1" is not a valid version of mono.', {:ansi=>:red}]
    end

    it 'throws a error for mono 1' do
      data[:config][:mono] = '1.1.8'
      should include_sexp [:echo, '"1.1.8" is not a valid version of mono.', {:ansi=>:red}]
    end

    it 'selects mono 2' do
      data[:config][:mono] = '2.10.8'
      should include_sexp [:cmd,'sudo apt-get install -qq mono-complete mono-vbnc', timing: true, assert: true]
    end

    it 'selects mono 3.2.8' do
      data[:config][:mono] = '3.2.8'
      should include_sexp [:cmd,'sudo apt-get install -qq mono-complete mono-vbnc fsharp', timing: true, assert: true]
    end

    it 'does not install PCL on mono 3.8.0' do
      data[:config][:mono] = '3.8.0'
      should include_sexp [:cmd, 'sudo apt-get install -qq mono-complete mono-vbnc fsharp nuget ', timing: true, assert: true]
    end

    it 'selects latest version by default' do
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", assert: true]
    end

    it 'selects correct version' do
      data[:config][:mono] = '3.12.0'
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy/snapshots/3.12.0 main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", assert: true]
    end
  end

  describe 'export' do
    it 'sets TRAVIS_SOLUTION' do
      data[:config][:solution] = 'foo.sln'
      should include_sexp [:export, ['TRAVIS_SOLUTION', 'foo.sln'], echo: true]
    end
  end

  describe 'announce' do
    it 'announces mono version' do
      should include_sexp [:cmd, 'mono --version', echo: true, timing: true]
    end

    it 'announces xbuild version' do
      should include_sexp [:cmd, 'xbuild /version', echo: true, timing: true]
    end
  end

  describe 'install' do
    it 'restores nuget from solution' do
      data[:config][:solution] = 'foo.sln'
      should include_sexp [:cmd, 'nuget restore foo.sln', assert: true, echo: true, timing: true, retry: true]
    end
  end

  describe 'script' do
    it 'throws an error when no script or solution is defined' do
      should include_sexp [:cmd, 'false']
    end

    it 'builds specified solution' do
      data[:config][:solution] = 'foo.sln'
      should include_sexp [:cmd, 'xbuild /p:Configuration=Release foo.sln', echo: true, timing: true]
    end
  end
end
