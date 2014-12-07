module Travis
  module CLI
    class Compile < RepoCommand
      description "compiles a build script from .travis.yml"

      attr_accessor :slug

      def setup
        error "run command is not available on #{RUBY_VERSION}" if RUBY_VERSION < '1.9.3'
        $:.unshift File.expand_path('../lib', __FILE__)
        require 'travis/build'
      end

      def run(*arg)
        @slug = find_slug
        if match_data = /\A(?<build>\d+)(\.(?<job>\d+))?\z/.match(arg.first)
          @build = build(match_data[:build])
          @job_number = match_data[:job].to_i - 1
          @config = @build.jobs[@job_number].config
        elsif arg.length > 0
          warn "#{arg.first} does not look like a job number. Last build's first job is assumed."
          @config = last_build.jobs[0].config
        else
          config = travis_config
          global_env = []
          if config.has_key? 'env'
            if config['env']['matrix']
              warn 'env.matrix key is ignored'
            end
            global_env = config['env'].fetch('global', [])
            global_env.delete_if { |v| v.is_a? Hash }
          end

          warn 'matrix key is ignored' if config.has_key? 'matrix'

          unless config['os'].respond_to? :scan
            warn "Detected unsupported 'os' key value for local build script comilation. Setting to default, 'linux'."
            config['os'] = 'linux'
          end

          @config = config.delete_if {|k,v| k == 'env' }.delete_if {|k,v| k == 'matrix' }
          @config['env'] = global_env
        end

        puts Travis::Build.script(data).compile(true)
      end

      private
        def data
          {
            :config => @config,
            :repository => {
              :slug => slug
            }
          }
        end
    end
  end
end
