module Travis
  module Build
    class Script
      module RVM
        def cache_slug
          super << "--rvm-" << ruby_version.to_s
        end

        def export
          super
          sh.export 'TRAVIS_RUBY_VERSION', config[:rvm], echo: false
        end

        def setup
          super
          config[:ruby] ? setup_chruby : setup_rvm
        end

        def announce
          super
          sh.cmd 'ruby --version'
          if config[:ruby]
            sh.cmd 'chruby --version'
          else
            sh.cmd 'rvm --version'
          end
        end

        private

        def ruby_version
          config[:rvm].to_s.gsub(/-(1[89]|2[01])mode$/, '-d\1')
        end

        def setup_chruby
          sh.echo 'BETA: Using chruby to select Ruby version. This is currently a beta feature and may change at any time.', color: :yellow
          sh.cmd 'curl -sLo ~/chruby.sh https://gist.githubusercontent.com/henrikhodne/a01cd7367b12a59ee051/raw/chruby.sh', echo: false
          sh.cmd 'source ~/chruby.sh', echo: false
          sh.cmd "chruby #{config[:ruby]}", timing: false
        end

        def setup_rvm
          sh.file '$rvm_path/user/db', %w(
            rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies/binaries
            rvm_remote_server_type3=rubies
            rvm_remote_server_verify_downloads3=1
          ).join("\n")

          if ruby_version =~ /ruby-head/
            sh.fold('rvm.1') do
              sh.echo 'Setting up latest %s' % ruby_version, ansi: :yellow
              sh.cmd "rvm get stable", assert: false if ruby_version == 'jruby-head'
              sh.export 'ruby_alias', "`rvm alias show #{ruby_version} 2>/dev/null`"
              sh.cmd "rvm alias delete #{ruby_version}", assert: false
              sh.cmd "rvm remove ${ruby_alias:-#{ruby_version}} --gems", assert: false
              sh.cmd "rvm remove #{ruby_version} --gems --fuzzy", assert: false
              sh.cmd "rvm install #{ruby_version} --binary"
            end
            sh.cmd "rvm use #{ruby_version}"
          elsif ruby_version == 'default'
            sh.if '-f .ruby-version' do
              sh.echo 'BETA: Using Ruby version from .ruby-version. This is a beta feature and may be removed in the future.', color: :yellow
              sh.fold('rvm.1') do
                sh.cmd 'rvm use . --install --binary --fuzzy'
              end
            end
            sh.else do
              sh.cmd "rvm use default", timing: false
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
