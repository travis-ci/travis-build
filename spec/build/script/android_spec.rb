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
      expect(subject.flatten.join).not_to include('android.install')
    end

    it 'sets up the Android environment variables' do
      android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
      sdkmanager_bin = "#{android_home}/cmdline-tools/bin/sdkmanager"
      
      should include_sexp [:export, 'ANDROID_HOME', android_home]
      should include_sexp [:export, 'PATH', "#{File.dirname(sdkmanager_bin)}:#{android_home}/tools:#{android_home}/tools/bin:#{android_home}/platform-tools:$PATH"]
      should include_sexp [:cmd, "mkdir -p #{File.dirname(sdkmanager_bin)}", echo: false]
    end

    it 'shows available build-tools versions when none specified' do
      android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
      sdkmanager_bin = "#{android_home}/cmdline-tools/bin/sdkmanager"
      
      should include_sexp [:echo, "No build-tools version specified in android.components. Consider adding one of the following:", ansi: :yellow]
      should include_sexp [:cmd, "#{sdkmanager_bin} --list | grep 'build-tools' | cut -d'|' -f1", echo: false, timing: false]
      should include_sexp [:echo, "The following versions are preinstalled:", ansi: :yellow]
      should include_sexp [:cmd, "for v in $(ls #{android_home}/build-tools | sort -r 2>/dev/null); do echo build-tools-$v; done; echo", echo: false, timing: false]
    end

    it 'installs the provided sdk components' do
      android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
      sdkmanager_bin = "#{android_home}/cmdline-tools/bin/sdkmanager"
      components = %w(build-tools-30.0.3 platforms-android-30 system-images-android-30-google-x86)

      data[:config][:android][:components] = components
      
      should include_sexp [:fold, 'android.install', fold_options]
      should include_sexp [:echo, 'Installing Android dependencies']
      should include_sexp [:cmd, "yes | #{sdkmanager_bin} --sdk_root=#{android_home} --licenses >/dev/null || true", echo: true]
      
      components.each do |component|
        if component =~ /^build-tools-(.+)$/
          sdk_name = "build-tools;#{$1}"
        elsif component =~ /^platform-tools-(.+)$/
          sdk_name = "platform-tools"
        elsif component =~ /^tools-(.+)$/
          sdk_name = "tools"
        elsif component =~ /^platforms-android-(.+)$/
          sdk_name = "platforms;android-#{$1}"
        elsif component =~ /^system-images-android-(.+)-(.+)-(.+)$/
          sdk_name = "system-images;android-#{$1};#{$2};#{$3}"
        else
          sdk_name = component
        end
        
        should include_sexp [:cmd, "yes | #{sdkmanager_bin} --sdk_root=#{android_home} \"#{sdk_name}\" --verbose", options]
      end
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

  def fold_options
    {
      animate: true,
      echo: true,
      timing: true
    }
  end
end
