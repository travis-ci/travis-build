module Travis
  module Build
    class Script
      class Perl < Script
        DEFAULTS = {
          perl: '5.14'
        }

        def export
          super
          sh.export 'TRAVIS_PERL_VERSION', version, echo: false
        end

        def setup
          super
          sh.cmd "perlbrew use #{version}"
        end

        def announce
          super
          sh.cmd 'perl --version', timing: true
          sh.cmd 'cpanm --version', timing: true
        end

        def install
          sh.cmd 'cpanm --quiet --installdeps --notest .', fold: 'install', retry: true
        end

        def script
          sh.if '-f Build.PL' do
            sh.cmd 'perl Build.PL && ./Build && ./Build test'
          end
          sh.elif '-f Makefile.PL' do
            sh.cmd 'perl Makefile.PL && make test'
          end
          sh.else do
            sh.cmd 'make test'
          end
        end

        def cache_slug
          super << '--perl-' << version
        end

        # safe_yaml parses strings like 5.10 to 5.1
        VERSIONS = {
          5.1 => '5.10',
          5.2 => '5.20'
        }

        def version
          version = config[:perl]
          VERSIONS[version] || version
        end
      end
    end
  end
end
