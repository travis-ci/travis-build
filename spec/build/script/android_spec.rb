require 'spec_helper'

describe Travis::Build::Script::Android, :sexp do
  let(:data)   { payload_for(:push, :android) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=android'] }
    let(:cmds) { ['gradlew build connectedCheck'] }
  end

  it_behaves_like 'a build script sexp'
  it_behaves_like 'a jdk build sexp'
  it_behaves_like 'announces java versions'

  describe 'on setup' do
    let(:options) { { assert: true, echo: true, timing: true } }

    before { data[:config][:android] = {} }

    it 'does not install any sdk component by default' do
      expect(subject.flatten.join).not_to include('android-sdk-update')
    end

    it 'installs the provided sdk components accepting provided license patterns' do
      components = %w(build-tools-19.0.3 android-19 sysimg-19 sysimg-18)
      licenses   = %w(android-sdk-license-.+ intel-.+)

      data[:config][:android][:components] = components
      data[:config][:android][:licenses]   = licenses

      components.each do |component|
        cmd = "android-update-sdk --components=#{component} --accept-licenses='#{licenses.join('|')}'"
        should include_sexp [:cmd, cmd, options]
      end
    end

    it 'installs the provided sdk components accepting a single license' do
      components = %w(sysimg-19 sysimg-18)
      license    = 'mips-android-sysimage-license-15del8cc'

      data[:config][:android][:components] = components
      data[:config][:android][:licenses]   = [license]

      components.each do |component|
        cmd = "android-update-sdk --components=#{component} --accept-licenses='#{license}'"
        should include_sexp [:cmd, cmd, options]
      end
    end

    it 'installs the provided sdk component using license defaults' do
      data[:config][:android][:components] = %w(build-tools-18.1.0)
      should include_sexp [:cmd, 'android-update-sdk --components=build-tools-18.1.0', options]
      should_not include_sexp [:cmd, 'android-update-sdk --components=build-tools-18.1.0 --accept-licenses', options]
    end
  end

  describe 'script' do
    let(:sexp) { sexp_find(subject, [:if, '-f gradlew']) }

    let(:gradlew_connected_check) { [:cmd, './gradlew build connectedCheck', echo: true, timing: true] }
    let(:gradle_connected_check)  { [:cmd, 'gradle build connectedCheck', echo: true, timing: true] }
    let(:mvn_install_b)           { [:cmd, 'mvn install -B', echo: true, timing: true] }
    let(:ant_install_test)        { [:cmd, 'ant debug install test', echo: true, timing: true] }

    it 'runs ./gradlew build connectedCheck if ./gradlew exists' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp gradlew_connected_check
    end

    it 'runs gradle build connectedCheck if ./gradlew does not exist' do
      branch = sexp_find(sexp, [:elif, '-f build.gradle'])
      expect(branch).to include_sexp gradle_connected_check
    end

    it 'runs mvn install -B if pom.xml exists' do
      branch = sexp_find(sexp, [:elif, '-f pom.xml'])
      expect(branch).to include_sexp mvn_install_b
    end

    it 'runs default android ant tasks if neither gradle nor mvn are used' do
      branch = sexp_find(sexp, [:else])
      expect(branch).to include_sexp ant_install_test
    end
  end
end
