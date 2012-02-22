module Travis
  class Build
    module Job
      class Test
        class Perl < Test
          class Config < Hashr
          end

          def setup
            super
            # cpanm modules will be stored here. Should be writeable and
            # local/unique to this particular Perl version. Per discussion with Duke Leto. MK.
            shell.execute "mkdir -p #{cpanm_modules_location}"
            shell.execute "export PERL_CPANM_OPT=#{cpanm_modules_location}"
            shell.execute "perlbrew use #{config.perl}"
            announce_versions
          end

          def cpanm_modules_location
            "~/perl5/perlbrew/perls/#{config.perl}/cpanm"
          end

          def install
            "cpanm -vv --installdeps --notest ."
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
        end
      end
    end
  end
end
