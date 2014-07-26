require 'travis/shell/generator'

module Travis
  module Shell
    class Generator
      class Bash < Shell::Generator
        require 'travis/shell/generator/bash/cmd'
        require 'travis/shell/generator/bash/helpers'

        include Helpers

        def handle_cmd(code, options = {})
          Cmd.new(code, options).to_bash
        end

        def handle_cd(path, options = {})
          handle_cmd("cd #{path}", options)
        end

        def handle_chmod(data, options = {})
          mode, path = *data
          handle_cmd("chmod #{mode} #{path}", options)
        end

        def handle_echo(message = '', options = {})
          message = " #{ansi(escape(message), options.delete(:ansi))}" unless message.empty?
          handle_cmd("echo#{message}", options)
        end

        def handle_newline(options = {})
          handle_echo
        end

        def handle_export(data, options = {})
          options[:echo] = "#{data.first}=[secure]" if options[:echo] && options[:secure]
          handle_cmd("export #{data.first}=#{escape(data.last)}", options)
        end

        def handle_file(data, options = {})
          path, content = *data
          cmd = ['echo', escape(content)]
          cmd << '| base64 --decode' if options[:decode]
          cmd << (options[:append] ? '>>' : '>')
          cmd << path
          handle_cmd(cmd.join(' '))
        end

        def handle_rm(path, options = {})
          opts = []
          opts << 'r' if options[:recursive]
          opts << 'f' if options[:force]
          opts = opts.any? ? "-#{opts.join}" : nil
          handle_cmd(['rm', opts, path].compact.join(' '))
        end

        def handle_fold(name, cmds, options = {})
          with_margin do
            lines = ["travis_fold start #{name}"]
            lines << handle(cmds)
            lines << "travis_fold end #{name}"
            lines
          end
        end

        def handle_if(condition, *branches)
          with_margin do
            lines = ["if [[ #{condition} ]]; then"]
            lines += branches.map { |branch| handle(branch) }
            lines << 'fi'
            lines
          end
        end

        def handle_then(cmds)
          handle(cmds)
        end

        def handle_elif(condition, cmds)
          lines = ["elif [[ #{condition} ]]; then"]
          lines += handle(cmds)
          lines
        end

        def handle_else(cmds)
          ['else', handle(cmds)]
        end
      end
    end
  end
end
