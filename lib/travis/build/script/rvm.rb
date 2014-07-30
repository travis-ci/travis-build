module Travis
  module Build
    class Script
      module RVM
        def cache_slug
          super << "--rvm-" << ruby_version.to_s
        end

        def export
          super
          set 'TRAVIS_RUBY_VERSION', config[:rvm], echo: false
        end

        def setup
          super
          config[:ruby] ? setup_chruby : setup_rvm
        end

        def announce
          super
          cmd 'ruby --version'
          if config[:ruby]
            cmd 'chruby --version'
          else
            cmd 'rvm --version'
          end
        end

        private

        def ruby_version
          config[:rvm].to_s.gsub(/-(1[89]|2[01])mode$/, '-d\1')
        end

        def setup_chruby
          echo 'BETA: Using chruby to select Ruby version. This is currently a beta feature and may change at any time."', color: :yellow
          cmd "curl -sLo ~/chruby.sh https://gist.githubusercontent.com/henrikhodne/a01cd7367b12a59ee051/raw/chruby.sh", echo: false
          cmd "source ~/chruby.sh", echo: false
          cmd "chruby #{config[:ruby]}"
        end

        def setup_rvm
          file '$rvm_path/user/db', %w(
            rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies/binaries
            rvm_remote_server_type3=rubies
            rvm_remote_server_verify_downloads3=1
          ).join("\n")

          if ruby_version =~ /ruby-head/
            fold("rvm.1") do
              echo 'Setting up latest %s' % ruby_version, ansi: :yellow
              cmd "rvm get stable", assert: false if ruby_version == 'jruby-head'
              set 'ruby_alias', "`rvm alias show #{ruby_version} 2>/dev/null`"
              cmd "rvm alias delete #{ruby_version}", assert: false
              cmd "rvm remove ${ruby_alias:-#{ruby_version}} --gems", assert: false
              cmd "rvm remove #{ruby_version} --gems --fuzzy", assert: false
              cmd "rvm install #{ruby_version} --binary"
            end
            cmd "rvm use #{ruby_version}"
          elsif ruby_version == 'default'
            self.if "-f .ruby-version" do |sh|
              sh.echo 'BETA: Using Ruby version from .ruby-version. This is a beta feature and may be removed in the future.', color: :yellow
              fold("rvm.1") { sh.cmd "rvm use . --install --binary --fuzzy" }
            end
            self.else "rvm use default"
          else
            fold("rvm.1") { cmd "rvm use #{ruby_version} --install --binary --fuzzy" }
          end
        end
      end
    end
  end
end
