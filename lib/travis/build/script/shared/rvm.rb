module Travis
  module Build
    class Script
      module RVM
        include Chruby

        def export
          super
          sh.export 'TRAVIS_RUBY_VERSION', config[:rvm], echo: false if rvm?
        end

        def setup
          super
          setup_rvm if rvm?
        end

        def announce
          super
          sh.cmd 'ruby --version'
          sh.cmd 'rvm --version' if rvm?
        end

        def cache_slug
          super.tap { |slug| slug << "--rvm-" << ruby_version.to_s if rvm? }
        end

        private

          def rvm?
            !!config[:rvm]
          end

          def ruby_version
            config[:rvm].to_s.gsub(/-(1[89]|2[01])mode$/, '-d\1')
          end

          def setup_rvm
            config = %w(
              rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies/binaries
              rvm_remote_server_type3=rubies
              rvm_remote_server_verify_downloads3=1
            )
            sh.file '$rvm_path/user/db', config.join("\n")

            if ruby_version =~ /ruby-head/
              sh.fold('rvm.1') do
                sh.echo 'Setting up latest %s' % ruby_version, ansi: :yellow
                sh.cmd "rvm get stable", assert: false if ruby_version == 'jruby-head'
                sh.export 'ruby_alias', "`rvm alias show #{ruby_version} 2>/dev/null`"
                sh.cmd "rvm alias delete #{ruby_version}"
                sh.cmd "rvm remove ${ruby_alias:-#{ruby_version}} --gems"
                sh.cmd "rvm remove #{ruby_version} --gems --fuzzy"
                sh.cmd "rvm install #{ruby_version} --binary"
              end
              sh.cmd "rvm use #{ruby_version}"
            elsif ruby_version == 'default'
              sh.if '-f .ruby-version' do
                sh.echo 'BETA: Using Ruby version from .ruby-version. This is a beta feature and may be removed in the future.' #, ansi: :yellow
                sh.fold('rvm.1') do
                  sh.cmd 'rvm use . --install --binary --fuzzy'
                end
              end
              sh.else do
                sh.cmd "rvm use default", timing: true
              end
            else
              sh.fold('rvm.1') do
                sh.cmd "rvm use #{ruby_version} --install --binary --fuzzy"
              end
            end
          end
      end
    end
  end
end
