require 'travis/build/script/shared/jdk'

module Travis
  module Build
    class Script
      class Android < Script
        DEFAULTS = {}

        include Jdk

        def setup
          super
          set_android_environment_variables
          install_sdk_components unless components.empty?
        end

        def script
          sh.if '-f gradlew' do
            sh.cmd './gradlew build connectedCheck'
          end
          sh.elif '-f build.gradle' do
            sh.cmd 'gradle build connectedCheck'
          end
          sh.elif '-f pom.xml' do
            sh.cmd 'mvn install -B', echo: true
          end
          sh.else do
            sh.cmd 'ant debug install test'
          end
        end

        private

        def set_android_environment_variables
          android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
          sdk_root = "#{android_home}/android-sdk"
          sdkmanager_path = "#{sdk_root}/cmdline-tools/latest/bin"

          sh.export 'ANDROID_HOME', android_home
          sh.export 'ANDROID_SDK_ROOT', sdk_root
          sh.export 'PATH', "#{sdkmanager_path}:#{sdk_root}/platform-tools:$PATH"

          sh.cmd "mkdir -p #{sdk_root}/licenses #{sdk_root}/.android", echo: false
          sh.cmd "touch #{sdk_root}/.android/repositories.cfg", echo: false

          sh.cmd "echo '24333f8a63b6825ea9c5514f83c2829b004d1fee' > #{sdk_root}/licenses/android-sdk-license", echo: false
          sh.cmd "echo '84831b9409646a918e30573bab4c9c91346d8abd' > #{sdk_root}/licenses/android-sdk-preview-license", echo: false
        end

        def install_sdk_components
          sh.fold 'android.install' do
            sh.echo 'Installing Android dependencies'
            components.each { |name| sh.cmd install_sdk_component(name) }
          end
        end

        def install_sdk_component(name)
          android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
          sdk_root = "#{android_home}/android-sdk"

          sdk_name = case name
                     when /^build-tools-(.+)$/ then "build-tools;#{$1}"
                     when /^platforms-android-(.+)$/ then "platforms;android-#{$1}"
                     when /^system-images-android-(.+)-(.+)-(.+)$/ then "system-images;android-#{$1};#{$2};#{$3}"
                     else name
                   end

          "mkdir -p #{sdk_root}/.android && touch #{sdk_root}/.android/repositories.cfg && " +
          "yes | sdkmanager --sdk_root='#{sdk_root}' '#{sdk_name}' --verbose || " +
          "(echo 'Retrying installation...' && yes | sdkmanager --sdk_root='#{sdk_root}' '#{sdk_name}' --verbose)"
        end

        def components
          android_config[:components] || []
        end

        def android_config
          config[:android] || {}
        end
      end
    end
  end
end
