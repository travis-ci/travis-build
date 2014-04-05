require 'spec_helper'

describe Travis::Build::Script::Android do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'
  it_behaves_like 'a jdk build'

  context 'on setup' do

    before :each do
      data['config']['android'] = {}
    end

    it 'does not install any sdk component by default' do
      should_not setup "android-update-sdk"
    end

    it 'installs the provided sdk components accepting provided license patterns' do
      data['config']['android']['components'] = %w[build-tools-19.0.3 android-19 sysimg-19 sysimg-18]
      data['config']['android']['licenses']   = %w[android-sdk-license-.+ intel-.+]

      # FIXME: There is a regexp problem with licenses='...' quotes in `asserts?` matcher,
      # so let's "temporary" use 'run' instead of 'setup'
      should run "android-update-sdk --components=build-tools-19.0.3 --accept-licenses='android-sdk-license-.+|intel-.+'", fold: true
      should run "android-update-sdk --components=android-19 --accept-licenses='android-sdk-license-.+|intel-.+'", fold: true
      should run "android-update-sdk --components=sysimg-19 --accept-licenses='android-sdk-license-.+|intel-.+'", fold: true
      should run "android-update-sdk --components=sysimg-18 --accept-licenses='android-sdk-license-.+|intel-.+'", fold: true
    end

    it 'installs the provided sdk components accepting a single license' do
      data['config']['android']['components'] = %w[sysimg-14 sysimg-8]
      data['config']['android']['licenses']   = %w[mips-android-sysimage-license-15de68cc]

      # FIXME: There is a regexp problem with licenses='...' quotes in `asserts?` matcher,
      # so let's "temporary" use 'run' instead of 'setup'
      should run "android-update-sdk --components=sysimg-14 --accept-licenses='mips-android-sysimage-license-15de68cc'", fold: true
      should run "android-update-sdk --components=sysimg-8 --accept-licenses='mips-android-sysimage-license-15de68cc'", fold: true
    end

    it 'installs the provided sdk component using license defaults' do
      data['config']['android']['components'] = %w[build-tools-18.1.0]

      should setup "android-update-sdk --components=build-tools-18.1.0", fold: true
      should_not setup "android-update-sdk --components=build-tools-18.1.0 --accept-licenses", fold: true
    end
  end

  describe 'if build.gradle exists' do
    before :each do
      file('build.gradle')
    end

    context 'with gradle wrapper present' do
      before do
        executable('./gradlew')
      end

      it 'installs with ./gradlew assemble' do
        should run './gradlew assemble', echo: true, log: true, assert: true, timeout: timeout_for(:install)
      end

      it 'runs ./gradlew check connectedCheck' do
        should run './gradlew check connectedCheck', echo: true, log: true, timeout: timeout_for(:script)
      end
    end

    context 'without gradle wrapper' do
      it 'installs with gradle assemble' do
        should run 'gradle assemble', echo: true, log: true, assert: true, timeout: timeout_for(:install)
      end

      it 'runs gradle check connectedCheck' do
        should run 'gradle check connectedCheck', echo: true, log: true, timeout: timeout_for(:script)
      end
    end
  end

  describe 'if pom.xml exists' do
    before :each do
      file('pom.xml')
    end

    it 'installs with mvn install -DskipTests=true -B' do
      should run 'mvn install -DskipTests=true -B', echo: true, log: true, assert: true, timeout: timeout_for(:install)
    end

    it 'runs mvn test -B' do
      should run 'mvn test -B', echo: true, log: true, timeout: timeout_for(:script)
    end
  end

  describe 'if neither gradle nor mvn are used' do
    it 'runs default android ant tasks' do
      should run 'ant debug installt test', echo: true, log: true, timeout: timeout_for(:script)
    end
  end
end
