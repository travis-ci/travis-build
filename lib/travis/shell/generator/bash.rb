require 'core_ext/hash/compact'
require 'travis/shell/generator'
require 'json'

module Travis
  module Shell
    class Generator
      class Bash < Shell::Generator
        require 'travis/shell/generator/bash/cmd'
        require 'travis/shell/generator/bash/helpers'

        include Helpers

        def handle_cmd(code, options = {})
          options = options.compact
          if options.empty?
            handle_raw(code)
          else
            [Cmd.new(code, options).to_bash]
          end
        end

        def handle_echo(message = '', options = {})
          lines = Array(message).flat_map { |msg| msg.split("\n") }
          lines << '' if lines.empty?
          lines.map do |line|
            line = %( -e "#{ansi(line, options.delete(:ansi))}") unless line.empty?
            handle_cmd("echo#{line}", options)
          end
        end

        def handle_newline(options = {})
          handle_cmd('echo')
        end

        def handle_export(data, options = {})
          key, value, options = handle_secure_vars(*data, options)
          handle_cmd("export #{key}=#{value}", options)
        end
        alias handle_set handle_export

        def handle_cd(path, options = {})
          if options[:stack]
            cmd = path == :back ? 'popd' : "pushd #{path}"
            cmd = "#{cmd} &> /dev/null"
          else
            cmd = path == :back ? 'cd -' : "cd #{path}"
          end
          handle_cmd(cmd, options)
        end

        def handle_file(data, options = {})
          path, content = *data
          cmd = ['echo', escape(content)]
          cmd << '| base64 --decode' if options.delete(:decode)
          cmd << (options.delete(:append) ? '>>' : '>')
          cmd << path
          handle_cmd(cmd.join(' '), options)
        end

        def handle_mkdir(path, options = {})
          opts = []
          opts << 'p' if options.delete(:recursive)
          opts = opts.any? ? "-#{opts.join}" : nil
          handle_cmd(['mkdir', opts, path].compact.join(' '), options)
        end

        def handle_chmod(data, options = {})
          mode, path = *data
          opts = []
          opts << 'R' if options.delete(:recursive)
          opts = opts.any? ? "-#{opts.join}" : nil
          cmd = ['chmod', opts, mode, path].compact.join(' ')
          handle_cmd(cmd, options)
        end

        def handle_chown(data, options = {})
          owner, path = *data
          opts = []
          opts << 'R' if options.delete(:recursive)
          opts = opts.any? ? "-#{opts.join}" : nil
          cmd = ['chown', opts, owner, path].compact.join(' ')
          handle_cmd(cmd, options)
        end

        def handle_cp(data, options = {})
          source, target = *data
          opts = []
          opts << 'r' if options.delete(:recursive)
          opts = opts.any? ? "-#{opts.join}" : nil
          cmd = ['cp', opts, source, target].compact.join(' ')
          handle_cmd(cmd, options)
        end

        def handle_mv(data, options = {})
          source, target = *data
          cmd = ['mv', source, target].compact.join(' ')
          handle_cmd(cmd, options)
        end

        def handle_rm(path, options = {})
          opts = []
          opts << 'r' if options.delete(:recursive)
          opts << 'f' if options.delete(:force)
          opts = opts.any? ? "-#{opts.join}" : nil
          cmd = ['rm', opts, path].compact.join(' ')
          handle_cmd(cmd, options)
        end

        def handle_fold(name, cmds, options = {})
          with_margin do
            lines = ["travis_fold start #{name}"]
            lines << handle(cmds)
            lines << "travis_fold end #{name}"
            lines
          end
        end

        # format roughly based on the stackdriver trace api
        #   https://cloud.google.com/trace/docs/reference/v2/rest/v2/projects.traces/batchWrite
        def handle_trace(name, body, options = {})
          span_id = rand 1..MAX_SPAN_ID
          span_id = span_id.to_s(16).rjust(16, "0")
          name = (name.to_s.lines.first || '').gsub(/<<.*/, '...')

          start_span = {
            id: span_id,
            parent_id: parent_span_id,
            name: name,
            start_time: '__TRAVIS_TIMESTAMP__'
          }

          end_span = {
            id: span_id,
            end_time: '__TRAVIS_TIMESTAMP__',
            status: '__TRAVIS_STATUS__'
          }

          lines = ["travis_trace_span #{escape(start_span.to_json)}"]
          with_span(span_id) do
            body.each do |node|
              lines << handle(node)
            end
          end
          lines << "travis_trace_span #{escape(end_span.to_json)}"
          lines
        end

        def handle_trace_root(body, options = {})
          span_id = root_span_id

          start_span = {
            id: span_id,
            parent_id: nil,
            name: 'root',
            start_time: '__TRAVIS_TIMESTAMP__'
          }

          end_span = {
            id: span_id,
            end_time: '__TRAVIS_TIMESTAMP__',
            status: '__TRAVIS_STATUS__'
          }

          lines = ["travis_trace_span #{escape(start_span.to_json)}"]
          with_span(span_id) do
            body.each do |node|
              lines << handle(node)
            end
          end
          lines << "travis_trace_span #{escape(end_span.to_json)}"
          lines
        end

        def handle_if(condition, *branches)
          options = branches.last.is_a?(Hash) ? branches.pop : {}
          with_margin do
            condition = "[[ #{condition} ]]" unless options.delete(:raw)
            lines = ["if #{condition}; then"]
            lines += branches.map { |branch| handle(branch) }
            lines << 'fi'
            lines
          end
        end

        def handle_then(cmds)
          handle(cmds)
        end

        def handle_elif(condition, cmds, options = {})
          condition = "[[ #{condition} ]]" unless options.delete(:raw)
          lines = ["elif #{condition}; then"]
          lines += handle(cmds)
          lines
        end

        def handle_else(cmds)
          ['else', handle(cmds)]
        end

        private

          def handle_secure_vars(key, value, options)
            if options[:echo] && options[:secure]
              options[:echo] = "export #{key}=[secure]"
              # Mark secure value as safe for output *here only*
              # to ensure the presence of the previously tainted
              # value in any other strings will result in the
              # compiled script being tainted
              value = value.output_safe
            end
            [key, value, options]
          end
      end
    end
  end
end
