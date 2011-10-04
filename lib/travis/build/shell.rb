module Travis
  module Build
    class Shell
      autoload :Session, 'travis/build/shell/session'
      attr_reader :session

      def initialize(config, &block)
        @session = Session.new(config, &block)
      end

      def export(name, value)
        session.execute("export name=value")
      end

      def chdir(dir)
        shell.execute("mkdir -p #{dir}; cd #{dir}", :echo => false)
      end

      def cwd
        session.evaluate('pwd').strip
      end

      def file_exists?
        session.execute("test -f #{file_name}", :echo => false)
      end

      def evaluate(*args)
        session.evaluate(*args)
      end

      def execute(*args)
        session.execute(*args)
      end
      alias :run :execute
    end
  end
end

