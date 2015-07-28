module Travis
  module Build
    class Script
      module RVM
        include Chruby

        MSGS = {
          setup_ruby_head:   'Setting up latest %s',
          ruby_version_file: 'BETA: Using Ruby version from .ruby-version. This is a beta feature and may be removed in the future.'
        }

        CONFIG = %w(
          rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies/binaries
          rvm_remote_server_type3=rubies
          rvm_remote_server_verify_downloads3=1
        )

        DEFALUT_VERSION = 'default'

        def export
          super
          # for now, we take the rvm key if both are defined
          # see also:`#version` and `#version_manager`
          if rvm?
            sh.export 'TRAVIS_RUBY_VERSION', config[:rvm], echo: false
          elsif config[:ruby]
            sh.export 'TRAVIS_RUBY_VERSION', config[:ruby], echo: false
          else
            sh.export 'TRAVIS_RUBY_VERSION', DEFALUT_VERSION, echo: false
          end
        end

        def setup
          super
          setup_rvm unless chruby?
        end

        def announce
          super
          sh.cmd 'ruby --version'
          sh.cmd 'rvm --version' unless chruby?
        end

        def cache_slug
          super.tap { |slug| slug << "--#{version_manager}-" << ruby_version.to_s }
        end

        private

          def version
            if rvm?
              config[:rvm].to_s
            elsif chruby?
              config[:ruby].to_s
            else
              DEFALUT_VERSION
            end
          end

          def rvm?
            !!config[:rvm]
          end

          def ruby_version
            version.to_s.gsub(/-(1[89]|2[01])mode$/, '-d\1')
          end

          def setup_rvm
            sh.file '$rvm_path/user/db', CONFIG.join("\n")
            send rvm_strategy
          end

          def rvm_strategy
            return :use_ruby_head    if ruby_version.include?('ruby-head')
            return :use_default_ruby if ruby_version == 'default'
            :use_ruby_version
          end

          def use_ruby_head
            sh.fold('rvm') do
              sh.echo MSGS[:setup_ruby_head] % ruby_version, ansi: :yellow
              sh.cmd "rvm get stable", assert: false if ruby_version == 'jruby-head'
              sh.export 'ruby_alias', "`rvm alias show #{ruby_version} 2>/dev/null`"
              sh.cmd "rvm alias delete #{ruby_version}"
              sh.cmd "rvm remove ${ruby_alias:-#{ruby_version}} --gems"
              sh.cmd "rvm remove #{ruby_version} --gems --fuzzy"
              sh.cmd "rvm install #{ruby_version} --binary"
              sh.cmd "rvm use #{ruby_version}"
            end
          end

          def use_default_ruby
            sh.if '-f .ruby-version' do
              use_ruby_version_file
            end
            sh.else do
              use_rvm_default_ruby
            end
          end

          def use_ruby_version_file
            sh.echo MSGS[:ruby_version_file], ansi: :yellow
            sh.fold('rvm') do
              sh.cmd 'rvm use $(< .ruby-version) --install --binary --fuzzy'
            end
          end

          def use_rvm_default_ruby
            sh.fold('rvm') do
              sh.cmd "rvm use default", timing: true
            end
          end

          def use_ruby_version
            skip_deps_install if rbx?
            sh.fold('rvm') do
              sh.cmd "rvm use #{ruby_version} --install --binary --fuzzy"
            end
          end

          def rbx?
            /^(rbx\S*)/.match(version)
          end

          def skip_deps_install
            sh.cmd "rvm autolibs disable", echo: false, timing: false
          end

          def version_manager
            if rvm?
              'rvm'
            elsif chruby?
              'chruby'
            else
              'rvm'
            end
          end
      end
    end
  end
end
