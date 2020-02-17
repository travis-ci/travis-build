module Travis
  module Build
    class Script
      module RVM
        include Chruby

        MSGS = {
          setup_ruby_head:   'Setting up latest %s'
        }

        CONFIG = %w(
          rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies/binaries
          rvm_remote_server_type3=rubies
          rvm_remote_server_verify_downloads3=1
        )

        RVM_VERSION_ALIASES = {
          '2.3' => '2.3.8',
          '2.4' => '2.4.5',
          '2.5' => '2.5.4',
          '2.6' => '2.6.2',
        }

        RVM_GPG_KEY_IDS = %w(
          mpapis
          pkuczynski
        )

        BUNDLER2_RUBY = '2.3.0'

        def export
          super
          sh.export 'TRAVIS_RUBY_VERSION', version, echo: false if rvm?
        end

        def setup
          super
          if rvm?
            setup_rvm
            sh.newline
          end
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

          def version
            Array(config[:rvm]).first.to_s
          end

          def rvm?
            !!config[:rvm]
          end

          def ruby_version
            vers = version.gsub(/-(1[89]|2[01])mode$/, '-d\1')
            force_187_p371 vers
          end

          def import_gpg_key
            RVM_GPG_KEY_IDS.each do |id|
              sh.if "$(command -v gpg2)" do
                sh.cmd "command curl -sSL https://rvm.io/#{id}.asc | gpg2 --import -", assert: false
              end
              sh.else do
                sh.cmd "command curl -sSL https://rvm.io/#{id}.asc | gpg --import -", assert: false
              end
            end
          end

          def setup_rvm
            write_default_gems
            if without_teeny?(version)
              setup_rvm_aliases
            end
            sh.cmd('type rvm &>/dev/null || source ~/.rvm/scripts/rvm', echo: false, assert: false, timing: false)
            sh.file '$rvm_path/user/db', CONFIG.join("\n")
            send rvm_strategy

            install_bundler
          end

          def rvm_strategy
            return :use_truffleruby  if ruby_version.start_with?('truffleruby')
            return :use_ruby_head    if ruby_version.include?('ruby-head')
            return :use_default_ruby if ruby_version == 'default'
            :use_ruby_version
          end

          def use_ruby_head
            sh.fold('rvm') do
              import_gpg_key
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
            sh.fold('rvm') do
              sh.cmd 'rvm use $(< .ruby-version) --install --binary --fuzzy'
            end
          end

          def use_rvm_default_ruby
            sh.fold('rvm') do
              sh.cmd "rvm use default", timing: true
            end
          end

          def use_truffleruby
            skip_deps_install # Travis' LLVM 5.0 is not recognized by RVM
            sh.fold('rvm') do
              # TruffleRuby has frequent (~monthly) releases,
              # use latest RVM to have the latest version available.
              import_gpg_key
              sh.cmd "rvm get master"
              sh.cmd "rvm install #{ruby_version}"
              sh.cmd "rvm use #{ruby_version}"
            end
          end

          def use_ruby_version
            skip_deps_install if rbx?
            sh.fold('rvm') do
              if ruby_version.start_with? 'ree'
                sh.if "! $(rvm list | grep ree)" do
                  sh.echo "Installing REE from source. This may take a few minutes.", ansi: :yellow
                  sh.cmd "sed -i 's|^\\(ree_1.8.7_url\\)=.*$|\\1=https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rubyenterpriseedition|' ${TRAVIS_HOME}/.rvm/config/db"
                  sh.cmd "rvm use #{ruby_version} --install --fuzzy"
                end
                sh.else do
                  sh.cmd "rvm use #{ruby_version} --install --binary --fuzzy"
                end
              elsif ruby_version.start_with? 'jruby'
                import_gpg_key
                sh.echo "Updating RVM", ansi: :yellow
                sh.cmd "rvm get stable"
                sh.cmd "rvm use #{ruby_version} --install --binary --fuzzy"
              else
                sh.cmd "rvm use #{ruby_version} --install --binary --fuzzy"
              end
            end
          end

          def rbx?
            /^(rbx\S*)/.match(version)
          end

          def skip_deps_install
            sh.cmd "rvm autolibs disable", echo: false, timing: false
          end

          def write_default_gems
            sh.mkdir '$rvm_path/gemsets', recursive: true, echo: false
            sh.cmd 'echo -e "gem-wrappers\nrubygems-bundler\nbundler\nrake\nrvm\n" > $rvm_path/gemsets/global.gems', echo: false, timing: false
            sh.cmd 'echo -e "jruby-openssl\njruby-launcher\ngem-wrappers\nrubygems-bundler\nbundler\nrake\nrvm\n" > $rvm_path/gemsets/jruby/global.gems', echo: false, timing: false
          end

          def force_187_p371(version)
            version.gsub(/^1\.8\.7.*$/, '1.8.7-p371')
          end

          def setup_rvm_aliases
            RVM_VERSION_ALIASES.select {|k,v| k == version}.each do |alias_version, real_version|
              grep_str = alias_version.gsub('.', '\\\\\\.')
              sh.if "-z $(rvm alias list | grep ^#{grep_str})" do
                sh.cmd "rvm alias create #{alias_version} ruby-#{real_version}", echo: true, assert: true
              end
            end
          end

          def without_teeny?(version)
            version =~ /\A(\d+)(\.\d+)\z/
          end

          def install_bundler
            sh.if "! $(command -v bundle)" do
              sh.fold "install_bundler" do
                sh.if "$(travis_vers2int \"$(ruby -e 'puts RUBY_VERSION')\") -lt $(travis_vers2int #{BUNDLER2_RUBY})" do
                  sh.cmd "gem install bundler -v '< 2'"
                end
                sh.else do
                  sh.cmd "gem install bundler"
                end
              end
            end
          end
      end
    end
  end
end
