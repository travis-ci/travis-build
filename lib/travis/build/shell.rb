require 'active_support/core_ext/module/delegation'

module Travis
  module Build
    class Shell
      autoload :Buffer,  'travis/build/shell/buffer'
      autoload :Helpers, 'travis/build/shell/helpers'
      autoload :Session, 'travis/build/shell/session'

      attr_reader :session

      delegate :connect, :close, :on_output, :evaluate, :execute, :to => :session

      def initialize(session)
        @session = session
      end

      def export(name, value, options = {})
        session.execute("export #{name}=#{value}", options) if name
      end

      def chdir(dir)
        session.execute("mkdir -p #{dir}; cd #{dir}", :echo => false)
      end

      def cwd
        session.evaluate('pwd').strip
      end

      def file_exists?(filename)
        session.execute("test -f #{filename}", :echo => false)
      end
    end
  end
end
