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
          warn 'env key is ignored' if config.has_key? 'env'
          warn 'matrix key is ignored' if config.has_key? 'matrix'

          @config = config.delete_if {|k,v| k == 'env' }.delete_if {|k,v| k == 'matrix' }
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
