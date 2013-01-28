module Travis
  module Build
    module Shell
      module Windows
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
              "Write-Host #{escape("$ #{echo || @code}")}\n#{code}"
            end
          end
        end
        class Builder
          include Dsl

          def escape(code)
            code.gsub('"','`"')
          end

          def set(var, value, options = {})
            cmd "set #{var}=#{value}", options.merge(log: false)
          end

          def echo(string, options = {})
            cmd "echo #{escape(string)}", echo: false, log: true
          end

          def cd(path)
            cmd "cd #{path}",echo: true, log: false
            cmd "[System.IO.Directory]::SetCurrentDirectory(#{path})", echo: false, log: false
          end

          def if_cmd(name,condition)
            "#{name} ( #{condition} ) \n {"
          end

          def close_conditional()
            "}"
          end

          def sh_if_file(name, &block)
            self.if("Test-Path #{name}",&block)
          end

          def rmf(file)
            raw "If(Test-Path #{file}) {\n\tRemove-Item -Force #{file}\n}"
          end
        end
      end
    end
  end
end