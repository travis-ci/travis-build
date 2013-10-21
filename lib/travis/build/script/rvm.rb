module Travis
  module Build
    class Script
      module RVM
        USER_DB = %w[
          rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies
          rvm_remote_server_path3=binary
          rvm_remote_server_verify_downloads3=1
        ].join("\n")

        def cache_slug
          super << "--rvm-" << ruby_version.to_s
        end

        def export
          super
          set 'TRAVIS_RUBY_VERSION', config[:rvm], echo: false
        end

        def setup
          super
          cmd "echo '#{USER_DB}' > $rvm_path/user/db", echo: false
          if ruby_version =~ /ruby-head/
            fold("rvm.1") do
              cmd 'echo -e "\033[33;1mSetting up latest %s\033[0m"' % ruby_version, assert: false, echo: false
              cmd "rvm get stable", assert: false if ruby_version == 'jruby-head'
              cmd "export ruby_alias=`rvm alias show #{ruby_version} 2>/dev/null`", assert: false
              cmd "rvm alias delete #{ruby_version}", assert: false
              cmd "rvm remove ${ruby_alias:-#{ruby_version}} --gems", assert: false
              cmd "rvm remove #{ruby_version} --gems --fuzzy", assert: false
              cmd "rvm install #{ruby_version} --binary"
            end
            cmd "rvm use #{ruby_version}"
          else
            cmd "rvm use #{ruby_version} --install --binary --fuzzy"
          end
        end

        def announce
          super
          cmd 'ruby --version'
          cmd 'rvm --version'
        end

        private

        def ruby_version
          config[:rvm].to_s.
            gsub(/-(1[89]|2[01])mode$/, '-d\1').
            gsub(/^rbx$/, 'rbx-weekly-d18').
            gsub(/^rbx-d(\d{2})$/, 'rbx-weekly-d\1')
        end
      end
    end
  end
end
