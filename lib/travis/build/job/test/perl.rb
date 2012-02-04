class Build
    module Job
      class Test
        class Perl < Test
          class Config < Hashr
          end
          def install
            "cpanm --installdeps ."
          end

          def script
            if uses_module_build?
              run_tests_with_mb
            else
              run_tests_with_eumm
            end
          end

          protected

          def uses_module_build?
            @uses_module_build ||= shell.file_exists?('Build.PL')
          end

          def uses_eumm
            @uses_eumm ||= shell.file_exists?('Makefile.PL')
          end

          def run_tests_with_mb
            "perl Build.PL && ./Build test"
          end

          def run_tests_with_eumm
            "perl Makefile.PL && make test"
          end

        end
      end
    end
  end
