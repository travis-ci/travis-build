module Travis
  module Build
    class Script
      class Perl < Script
        DEFAULTS = {
          perl: '5.14'
        }

        def export
          super
          sh.export 'TRAVIS_PERL_VERSION', version, echo: true
        end

        def setup
          super
          sh.cmd "perlbrew use #{version}", echo: true
        end

        def announce
          super
          sh.cmd 'perl --version', echo: true, timing: false
          sh.cmd 'cpanm --version', echo: true, timing: false
        end

        def install
          sh.cmd 'cpanm --quiet --installdeps --notest .', echo: true, fold: 'install', retry: true
        end

        def script
          sh.if '-f Build.PL' do
            sh.cmd 'perl Build.PL && ./Build && ./Build test', echo: true
          end
          sh.elif '-f Makefile.PL' do
            sh.cmd 'perl Makefile.PL && make test', echo: true
          end
          sh.else do
            sh.cmd 'make test', echo: true
          end
        end

        def cache_slug
          super << "--perl-" << version
        end

        def version
          # this check is needed because safe_yaml parses the string 5.10 to 5.1
          (config[:perl] == 5.1 ? "5.10" : config[:perl]).to_s
        end
      end
    end
  end
end
