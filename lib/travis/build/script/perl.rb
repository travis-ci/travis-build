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

        def configure
          super
          sh.if "! -x ${TRAVIS_HOME}/perl5/perlbrew/perls/#{version}/bin/perl" do
            sh.echo "#{version} is not installed; attempting download", ansi: :yellow
            install_perl_archive(version)
          end
        end

        def setup
          super
          sh.cmd "perlbrew use #{version}", assert: false
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
          '5.1' => '5.10',
          '5.2' => '5.20',
          '5.3' => '5.30'
        }

        def version
          version = Array(config[:perl]).first.to_s
          VERSIONS[version] || version
        end

        def install_perl_archive(version)
          sh.raw archive_url_for('travis-perl-archives', version)
          sh.echo "Downloading archive: ${archive_url}", ansi: :yellow
          sh.cmd "curl -sSf --retry 5 -o perl-#{version}.tar.bz2 ${archive_url}", echo: false
          sh.cmd "sudo tar xjf perl-#{version}.tar.bz2 --directory /", echo: true
          sh.cmd "rm perl-#{version}.tar.bz2", echo: false
        end

      end
    end
  end
end
