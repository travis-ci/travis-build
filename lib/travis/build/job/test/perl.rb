module Travis
  class Build
    module Job
      class Test
        class Perl < Test
          class Config < Hashr
            define :perl => '5.14'
          end

          def setup
            super
            shell.execute "perlbrew use #{config.perl}"
            announce_versions
          end

          def cpanm_modules_location
            "~/perl5/perlbrew/perls/#{config.perl}/cpanm"
          end

          def install
            "cpanm --quiet --installdeps --notest #{mirror_opts} ."
          end

          def announce_versions
            shell.execute("perl --version")
            shell.execute("cpanm --version")
          end

          def script
            if uses_module_build?
              run_tests_with_mb
            elsif uses_eumm?
              run_tests_with_eumm
            else
              run_default
            end
          end

          protected

            def uses_module_build?
              @uses_module_build ||= shell.file_exists?('Build.PL')
            end

            def uses_eumm?
              @uses_eumm ||= shell.file_exists?('Makefile.PL')
            end

            def run_tests_with_mb
              "perl Build.PL && ./Build test"
            end

            def run_tests_with_eumm
              "perl Makefile.PL && make test"
            end

            def run_default
              "make test"
            end

            def mirror_opts
              self.mirrors.map { |s| "--mirror #{s}" }.join(" ")
            end

            def mirrors
              %w(http://cpan.mirrors.travis-ci.org)
            end
        end
      end
    end
  end
end
