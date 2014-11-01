module Travis
  module Build
    class Script
      class Perl < Script
        DEFAULTS = {
          perl: '5.14'
        }

        def cache_slug
          super << "--perl-" << config[:perl].to_s
        end

        def export
          super
          sh.export 'TRAVIS_PERL_VERSION', perl_version, echo: false
        end

        def setup
          super
          sh.cmd "perlbrew use #{perl_version}"
        end

        def announce
          super
          sh.cmd 'perl --version'
          sh.cmd 'cpanm --version'
        end

        def install
          sh.cmd 'cpanm --quiet --installdeps --notest .', fold: 'install', retry: true
        end

        def script
          sh.if   '-f Build.PL',    'perl Build.PL && ./Build && ./Build test'
          sh.elif '-f Makefile.PL', 'perl Makefile.PL && make test'
          sh.else                   'make test'
        end

        def perl_version
          # this check is needed because safe_yaml parses the string 5.10 to 5.1
          if config[:perl] == 5.1
            "5.10"
          # this check is needed because safe_yaml parses the string 5.20 to 5.2
          elsif config[:perl] == 5.2
            "5.20"
          else
            config[:perl]
          end
        end
      end
    end
  end
end
