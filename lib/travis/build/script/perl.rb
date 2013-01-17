module Travis
  module Build
    class Script
      class Perl < Script
        DEFAULTS = {
          perl: '5.14'
        }

        def export
          super
          set 'TRAVIS_PERL_VERSION', config[:perl], echo: false
        end

        def setup
          super
          cmd "perlbrew use #{config[:perl]}"
        end

        def announce
          super
          cmd 'perl --version'
          cmd 'cpanm --version'
        end

        def install
          cmd 'cpanm --quiet --installdeps --notest .'
        end

        def script
          sh_if   '-f Build.PL',    'perl Build.PL && ./Build test'
          sh_elif '-f Makefile.PL', 'perl Makefile.PL && make test'
          sh_else                   'make test'
        end
      end
    end
  end
end
