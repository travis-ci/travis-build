module Travis
  module Build
    module Shell
      module Unix
        module Filters
          module Logging
            def code
              options[:log] && options[:log_file] ? log(super) : super
            end

            def log(code)
              "#{code} >> #{options[:log_file]} 2>&1"
            end
          end
          module Timeout
            def code
              options[:timeout] ? timeout(super) : super
            end

            def timeout(code)
              "tlimit -c #{options[:timeout]} #{code}"
            end
          end

          module Assertion
            def code
              options[:assert] ? assert(super) : super
            end

            def assert(code)
              "#{code}\ntravis_assert"
            end
          end

          module Echoize
            def code
              echo = options[:echo]
              echo ? echoize(super, echo.is_a?(String) ? echo : nil) : super
              end

            def echoize(code, echo = nil)
              "echo #{escape("$ #{echo || @code}")}\n#{code}"
            end
          end
        end

        def escape(code)
          Shellwords.escape(code)
        end

        def set(var, value, options = {})
          cmd "export #{var}=#{value}", options.merge(log: false)
        end

        def echo(string, options = {})
          cmd "echo #{escape(string)}", echo: false, log: true
        end

        def cd(path)
          cmd "cd #{path}", echo: true, log: false
        end

        def if_cmd(name,condition)
          "#{name} [[ #{condition} ]]; then"
        end

        def close_conditional()
          "fi"
        end

        def test_file_cmd(name)
          "-f ${name}"
        end

        def rmf(file)
          raw "rm -f #{file}"
        end
      end
    end
  end
end