module Travis
  module Build
    class Script
      class Pharo < Script
        DEFAULTS = {
          pharo: 'stable',  # stable, alpha, 50, 40"
          source_dir: '.'    # where the pharo sources actually are (usually root, ./mc or ./repository)
        }
        # baseline
        # test

        def configure
          super
          case config[:os]
          when 'linux'
            sh.fold 'install_packages' do
              sh.echo 'Installing libc6:i386 and libuuid1:i386', ansi: :yellow
              sh.cmd 'sudo apt-get update -qq', retry: true
              sh.cmd 'sudo apt-get install libc6:i386 libuuid1:i386 libkrb5-3:i386 libk5crypto3:i386 zlib1g:i386 libcomerr2:i386 libkrb5support0:i386 libkeyutils1:i386 libssl1.0.0:i386 libfreetype6:i386', retry: true
            end
          when 'osx'
            # do nothing
          end
        end

        def announce
          super
          sh.echo ''
          sh.cmd './pharo Pharo.image printVersion'
          sh.echo ''
        end

        def setup
          super
          sh.cmd "export PROJECT_HOME=\"$(pwd)\""
          sh.cmd "wget --quiet get.pharo.org/#{config[:version]}+vm | bash"
        end

        def install
          super
          if config[:baseline]
            sh.cmd "./pharo Pharo.image eval --save \"Metacello new filetreeDirectory: '#{config[:source_dir]}'; baseline: '#{config[:baseline]}'; load.\""
          else
            sh.failure "No baseline defined, exiting"
          end
        end

        def script
          super
          if config[:test]
            sh.cmd "./pharo Pharo.image test --fail-on-failure \"#{config[:test]}\""
          else
            sh.failure "No test packages defined, exiting"
          end
        end

        def export
            super
            sh.export 'PHARO', config[:pharo], echo: false
        end
      end
    end
  end
end
