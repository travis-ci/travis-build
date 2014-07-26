module Travis
  module Build
    class Script
      module RVM
        def export
          super
          set 'TRAVIS_RUBY_VERSION', config[:rvm]
        end

        def setup
          super
          config[:ruby] ? setup_chruby : setup_rvm
        end

        def announce
          super
          if config[:ruby]
            cmd 'chruby --version', echo: true, timing: false
          else
            cmd 'rvm --version', echo: true, timing: false
          end
        end

        def cache_slug
          super << "--rvm-" << ruby_version.to_s
        end

        private

          def ruby_version
            config[:rvm].to_s.gsub(/-(1[89]|2[01])mode$/, '-d\1')
          end

          def setup_chruby
            echo 'BETA: Using chruby to select Ruby version. This is currently a beta feature and may change at any time."', color: :green
            cmd "curl -sLo ~/chruby.sh https://gist.githubusercontent.com/henrikhodne/a01cd7367b12a59ee051/raw/chruby.sh"
            cmd "source ~/chruby.sh"
            cmd "chruby #{config[:ruby]}", assert: true, echo: true, timing: false
          end

          def setup_rvm
            setup_rvm_user_db

            if ruby_version =~ /ruby-head/
              setup_rvm_head
            elsif ruby_version == 'default'
              setup_rvm_default
            else
              setup_rvm_version
            end
          end

          def setup_rvm_user_db
            file '$rvm_path/user/db', %w(
              rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies/binaries
              rvm_remote_server_type3=rubies
              rvm_remote_server_verify_downloads3=1
            ).join("\n")
          end

          def setup_rvm_head
            fold 'rvm.setup' do
              sh.echo 'Setting up latest %s' % ruby_version, ansi: :green
              sh.cmd "rvm get stable", assert: false if ruby_version == 'jruby-head'
              sh.set 'ruby_alias', "`rvm alias show #{ruby_version} 2>/dev/null`"
              sh.cmd "rvm alias delete #{ruby_version}", assert: false
              sh.cmd "rvm remove ${ruby_alias:-#{ruby_version}} --gems", assert: false
              sh.cmd "rvm remove #{ruby_version} --gems --fuzzy", assert: false
              sh.cmd "rvm install #{ruby_version} --binary"
            end
            cmd "rvm use #{ruby_version}", assert: true, echo: true
          end

          def setup_rvm_default
            sh.if '-f .ruby-version' do
              sh.echo 'BETA: Using Ruby version from .ruby-version. This is a beta feature and may be removed in the future.', color: :green
              sh.fold 'rvm.setup' do
                sh.cmd 'rvm use . --install --binary --fuzzy', assert: true, echo: true
              end
            end
            sh.else do
              sh.cmd 'rvm use default', assert: true, echo: true, timing: false
            end
          end

          def setup_rvm_version
            fold 'rvm.setup' do
              sh.cmd "rvm use #{ruby_version} --install --binary --fuzzy", assert: true, echo: true
            end
          end
      end
    end
  end
end
