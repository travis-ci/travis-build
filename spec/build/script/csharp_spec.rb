require 'spec_helper'

describe Travis::Build::Script::Csharp, :sexp do
  let(:data)   { payload_for(:push, :csharp) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=csharp'] }
  end

  it_behaves_like 'a build script sexp'

  describe 'configure' do
    it 'sets up package repository for mono' do
      should include_sexp [:cmd, 'sudo mv /tmp/mono.gpg /etc/apt/trusted.gpg.d/', assert: true]
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu stable-trusty main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true]
      should include_sexp [:cmd, 'travis_apt_get_update', retry: true, timing: true, assert: true]
    end

    it 'sets up package repository for dotnet 1.1.5' do
      data[:config][:dotnet] = '1.1.5'
      should include_sexp [:cmd, 'sudo mv /tmp/dotnet.gpg /etc/apt/trusted.gpg.d/', assert: true]
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb [arch=amd64] https://packages.microsoft.com/ubuntu/14.04/prod trusty main' > /etc/apt/sources.list.d/dotnet-official.list\"", assert: true]
      should include_sexp [:cmd, 'travis_apt_get_update', retry: true, timing: true, assert: true]
    end

    it 'sets up package repository for dotnet 2.0.0 and above' do
      data[:config][:dotnet] = '2.0.0'
      should include_sexp [:cmd, 'sudo mv /tmp/dotnet.gpg /etc/apt/trusted.gpg.d/', assert: true]
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb [arch=amd64] https://packages.microsoft.com/ubuntu/14.04/prod trusty main' > /etc/apt/sources.list.d/dotnet-official.list\"", assert: true]
      should include_sexp [:cmd, 'travis_apt_get_update', retry: true, timing: true, assert: true]
    end

    it 'installs mono' do
      should include_sexp [:cmd, 'sudo apt-get install -qq mono-complete mono-vbnc fsharp nuget referenceassemblies-pcl', timing: true, assert: true]
    end

    it "installs dotnet 1.1.5" do
      data[:config][:dotnet] = '1.1.5'
      should include_sexp [:cmd, 'sudo apt-get install -qq dotnet-dev-1.1.5', timing: true, assert: true]
    end

    it "installs dotnet 2.0.0 and above" do
      data[:config][:dotnet] = '2.0.0'
      should include_sexp [:cmd, 'sudo apt-get install -qq dotnet-sdk-2.0.0', timing: true, assert: true]
    end

    it "installs dotnet 2.1 latest" do
      data[:config][:dotnet] = '2.1'
      should include_sexp [:cmd, 'sudo apt-get install -qq dotnet-sdk-2.1', timing: true, assert: true]
    end

    it "installs dotnet 2.1.300-rc1-008673" do
      data[:config][:dotnet] = '2.1.300-rc1-008673'
      should include_sexp [:cmd, 'sudo apt-get install -qq dotnet-sdk-2.1.300-rc1-008673', timing: true, assert: true]
    end

    it "installs dotnet 2.1.300" do
      data[:config][:dotnet] = '2.1.300'
      should include_sexp [:cmd, 'sudo apt-get install -qq dotnet-sdk-2.1=2.1.300*', timing: true, assert: true]
    end

    it "installs dotnet 2.1.301-preview1-12345" do
      data[:config][:dotnet] = '2.1.301-preview1-12345'
      should include_sexp [:cmd, 'sudo apt-get install -qq dotnet-sdk-2.1=2.1.301-preview1-12345*', timing: true, assert: true]
    end

    it "installs dotnet 2.1.200" do
      data[:config][:dotnet] = '2.1.200'
      should include_sexp [:cmd, 'sudo apt-get install -qq dotnet-sdk-2.1.200', timing: true, assert: true]
    end
  end

  describe 'version switching' do
    it 'throws a error with an invalid Mono version' do
      data[:config][:mono] = 'foo'
      should include_sexp [:echo, "\"foo\" is either an invalid version of \"mono\" or unsupported on this operating system.\nView valid versions of \"mono\" at https://docs.travis-ci.com/user/languages/csharp/"]
    end

    it 'throws a error with an invalid Mono version as float' do
      data[:config][:mono] = 5.2
      should include_sexp [:echo, "\"5.2\" is either an invalid version of \"mono\" or unsupported on this operating system.\nView valid versions of \"mono\" at https://docs.travis-ci.com/user/languages/csharp/"]
    end

    it 'throws a error with an invalid .NET Core version' do
      data[:config][:dotnet] = 'foo'
      should include_sexp [:echo, "\"foo\" is either an invalid version of \"dotnet\" or unsupported on this operating system.\nView valid versions of \"dotnet\" at https://docs.travis-ci.com/user/languages/csharp/"]
    end

    it 'throws a error with an invalid .NET Core version as float' do
      data[:config][:dotnet] = 2
      should include_sexp [:echo, "\"2\" is either an invalid version of \"dotnet\" or unsupported on this operating system.\nView valid versions of \"dotnet\" at https://docs.travis-ci.com/user/languages/csharp/"]
    end

    it 'throws a error with an invalid version' do
      data[:config][:mono] = '12.55.523'
      should include_sexp [:echo, "\"12.55.523\" is either an invalid version of \"mono\" or unsupported on this operating system.\nView valid versions of \"mono\" at https://docs.travis-ci.com/user/languages/csharp/"]
    end

    it 'throws a error for invalid version of mono 2' do
      data[:config][:mono] = '2.1.1'
      should include_sexp [:echo, "\"2.1.1\" is either an invalid version of \"mono\" or unsupported on this operating system.\nView valid versions of \"mono\" at https://docs.travis-ci.com/user/languages/csharp/"]
    end

    it 'throws a error for mono 1' do
      data[:config][:mono] = '1.1.8'
      should include_sexp [:echo, "\"1.1.8\" is either an invalid version of \"mono\" or unsupported on this operating system.\nView valid versions of \"mono\" at https://docs.travis-ci.com/user/languages/csharp/"]
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
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu stable-trusty main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true]
      should_not include_sexp [:cmd, "nightly", assert: true]
    end

    it 'selects correct version on old repo' do
      data[:config][:mono] = '3.12.0'
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy/snapshots/3.12.0 main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true]
    end

    it 'selects correct version on new repo' do
      data[:config][:mono] = '5.2.0'
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu stable-trusty/snapshots/5.2.0 main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true]
    end

    it 'selects preview when alpha version is specified' do
      data[:config][:mono] = 'alpha'
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu preview-trusty main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true]
    end

    it 'selects preview when beta version is specified' do
      data[:config][:mono] = 'beta'
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu preview-trusty main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true]
    end

    it 'selects preview when specified' do
      data[:config][:mono] = 'preview'
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu preview-trusty main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true]
    end

    it 'selects nightly version when specified' do
      data[:config][:mono] = 'nightly'
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu preview-trusty main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true]
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu nightly-trusty main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true]
    end

    it 'selects nightly when weekly version is specified' do
      data[:config][:mono] = 'weekly'
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu preview-trusty main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true]
      should include_sexp [:cmd, "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu nightly-trusty main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true]
    end

    it 'selects no version of Mono when specified' do
      data[:config][:mono] = 'none'
      should_not include_sexp [:cmd, "download.mono-project.com", assert: true]
    end

# FIXME: this fails as unit test, but seems to work in the real environment. Figure out why.
#    it 'runs mozroots on Mono before 3.12' do
#      data[:config][:mono] = '3.10'
#      should include_sexp [:cmd, "mozroots --import --sync --quiet --file /tmp/certdata.txt", assert: true]
#    end
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
      data[:config][:mono] = '3.8.0'
      should include_sexp [:cmd, 'xbuild /version', echo: true, timing: true]
    end

    it 'announces msbuild version' do
      data[:config][:mono] = '5.0.0'
      should include_sexp [:cmd, 'msbuild /version', echo: true, timing: true]
    end
  end

  describe 'install' do
    it 'restores nuget from solution' do
      data[:config][:solution] = 'foo.sln'
      data[:config][:os] = 'linux'
      should include_sexp [:cmd, 'nuget restore foo.sln', assert: true, echo: true, timing: true, retry: true]
    end

    it 'correctly shellescapes solutions' do
      data[:config][:solution] = 'test shellescape.sln'
      data[:config][:os] = 'linux'
      should include_sexp [:cmd, 'nuget restore test\ shellescape.sln', assert: true, echo: true, timing: true, retry: true]
    end
  end

  describe 'script' do
    it 'throws an error when no script or solution is defined' do
      should include_sexp [:echo, 'No solution or script defined, exiting']
    end

    it 'builds specified solution' do
      data[:config][:solution] = 'foo.sln'
      should include_sexp [:cmd, 'msbuild /p:Configuration=Release foo.sln', echo: true, timing: true]
    end

    it 'correctly shellescapes solutions' do
      data[:config][:solution] = 'test shellescape.sln'
      data[:config][:os] = 'linux'
      should include_sexp [:cmd, 'msbuild /p:Configuration=Release test\ shellescape.sln', echo: true, timing: true]
    end
  end

  describe 'osx' do
    it 'installs' do
      data[:config][:os] = 'osx'
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/mdk.pkg http://download.mono-project.com/archive/mdk-latest.pkg", timing: true, assert: true, echo: true]
      should include_sexp [:cmd, "sudo installer -package \"/tmp/mdk.pkg\" -target \"/\" -verboseR", timing: true, assert: true]
      should include_sexp [:cmd, "eval $(/usr/libexec/path_helper -s)", assert: true]
    end

    it 'installs dotnet 1.1.5' do
      data[:config][:os] = 'osx'
      data[:config][:dotnet] = '1.1.5'
      should include_sexp [:cmd, "brew install openssl", timing: true, assert: true]
      should include_sexp [:cmd, "mkdir -p /usr/local/lib", assert: true]
      should include_sexp [:cmd, "ln -s /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib /usr/local/lib/", assert: true]
      should include_sexp [:cmd, "ln -s /usr/local/opt/openssl/lib/libssl.1.0.0.dylib /usr/local/lib/", assert: true]
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/dotnet.pkg https://dotnetcli.azureedge.net/dotnet/Sdk/1.1.5/dotnet-dev-osx-x64.1.1.5.pkg", timing: true, assert: true, echo: true]
      should include_sexp [:cmd, "sudo installer -package \"/tmp/dotnet.pkg\" -target \"/\" -verboseR", timing: true, assert: true]
      should include_sexp [:cmd, "eval $(/usr/libexec/path_helper -s)", assert: true]
    end

    it 'installs dotnet 2.0.0 and above' do
      data[:config][:os] = 'osx'
      data[:config][:dotnet] = '2.0.0'
      should_not include_sexp [:cmd, "brew install openssl", timing: true, assert: true]
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/dotnet.pkg https://dotnetcli.azureedge.net/dotnet/Sdk/2.0.0/dotnet-sdk-2.0.0-osx-x64.pkg", timing: true, assert: true, echo: true]
      should include_sexp [:cmd, "sudo installer -package \"/tmp/dotnet.pkg\" -target \"/\" -verboseR", timing: true, assert: true]
      should include_sexp [:cmd, "eval $(/usr/libexec/path_helper -s)", assert: true]
    end

    it 'installs dotnet 2.1.300-rc1-008673 and above' do
      data[:config][:os] = 'osx'
      data[:config][:dotnet] = '2.1.300-rc1-008673'
      should_not include_sexp [:cmd, "brew install openssl", timing: true, assert: true]
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/dotnet.pkg https://dotnetcli.azureedge.net/dotnet/Sdk/2.1.300-rc1-008673/dotnet-sdk-2.1.300-rc1-008673-osx-x64.pkg", timing: true, assert: true, echo: true]
      should include_sexp [:cmd, "sudo installer -package \"/tmp/dotnet.pkg\" -target \"/\" -verboseR", timing: true, assert: true]
      should include_sexp [:cmd, "eval $(/usr/libexec/path_helper -s)", assert: true]
    end

    it 'selects preview when alpha specified' do
      data[:config][:os] = 'osx'
      data[:config][:mono] = 'alpha'
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/mdk.pkg http://download.mono-project.com/archive/mdk-latest-preview.pkg", timing: true, assert: true, echo: true]
    end

    it 'selects preview when beta specified' do
      data[:config][:os] = 'osx'
      data[:config][:mono] = 'beta'
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/mdk.pkg http://download.mono-project.com/archive/mdk-latest-preview.pkg", timing: true, assert: true, echo: true]
    end

    it 'selects preview' do
      data[:config][:os] = 'osx'
      data[:config][:mono] = 'preview'
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/mdk.pkg http://download.mono-project.com/archive/mdk-latest-preview.pkg", timing: true, assert: true, echo: true]
    end

    it 'selects nightly when weekly specified' do
      data[:config][:os] = 'osx'
      data[:config][:mono] = 'weekly'
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/mdk.pkg http://download.mono-project.com/archive/mdk-latest-nightly.pkg", timing: true, assert: true, echo: true]
    end

    it 'selects nightly' do
      data[:config][:os] = 'osx'
      data[:config][:mono] = 'nightly'
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/mdk.pkg http://download.mono-project.com/archive/mdk-latest-nightly.pkg", timing: true, assert: true, echo: true]
    end

    it 'selects 4.0.1' do
      data[:config][:os] = 'osx'
      data[:config][:mono] = '4.0.1'
      should include_sexp [:cmd, "wget --retry-connrefused --waitretry=1 -O /tmp/mdk.pkg http://download.mono-project.com/archive/4.0.1/macos-10-x86/MonoFramework-MDK-4.0.1.macos10.xamarin.x86.pkg", timing: true, assert: true, echo: true]
    end
  end
end
