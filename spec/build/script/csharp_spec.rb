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
      should include_sexp [:cmd, 'sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF']
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy main' >> /etc/apt/sources.list.d/mono-xamarin.list\""]
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy-libtiff-compat main' >> /etc/apt/sources.list.d/mono-xamarin.list\""]
      should include_sexp [:cmd, 'sudo apt-get update -qq', timing: true]
    end

    it 'installs mono' do
      should include_sexp [:cmd, 'sudo apt-get install -qq mono-complete referenceassemblies-pcl nuget mono-vbnc fsharp', timing: true]
      should include_sexp [:cmd, 'mozroots --import --sync --quiet', timing: true]
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
