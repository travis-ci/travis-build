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

  it 'installs the provided sdk components on setup' do
    data['config']['sdk_components'] = [
      'platform-tools',
      'android-18',
    ]
    is_expected.to setup "spawn android update sdk --filter platform-tools --no-ui --force", fold: true
    is_expected.to setup "spawn android update sdk --filter android-18 --no-ui --force", fold: true
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
        is_expected.to run './gradlew assemble', echo: true, log: true, assert: true, timeout: timeout_for(:install)
      end

      it 'runs ./gradlew check connectedCheck' do
        is_expected.to run './gradlew check connectedCheck', echo: true, log: true, timeout: timeout_for(:script)
      end
    end

    context 'without gradle wrapper' do
      it 'installs with gradle assemble' do
        is_expected.to run 'gradle assemble', echo: true, log: true, assert: true, timeout: timeout_for(:install)
      end

      it 'runs gradle check connectedCheck' do
        is_expected.to run 'gradle check connectedCheck', echo: true, log: true, timeout: timeout_for(:script)
      end
    end
  end

  describe 'if pom.xml exists' do
    before :each do
      file('pom.xml')
    end

    it 'installs with mvn install -DskipTests=true -B' do
      is_expected.to run 'mvn install -DskipTests=true -B', echo: true, log: true, assert: true, timeout: timeout_for(:install)
    end

    it 'runs mvn test -B' do
      is_expected.to run 'mvn test -B', echo: true, log: true, timeout: timeout_for(:script)
    end
  end

  describe 'if neither gradle nor mvn are used' do
    it 'runs default android ant tasks' do
      is_expected.to run 'ant debug installt test', echo: true, log: true, timeout: timeout_for(:script)
    end
  end
end
