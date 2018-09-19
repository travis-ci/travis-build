module Travis
  module Build
    module Bash
      def bash(name, encode: false)
        bytes = bash_pathname(name).read.untaint
        return Base64.encode64(bytes) if encode
        bytes
      end

      private def bash_pathname(name)
        Pathname.new(File.expand_path("./bash/#{name}.bash", __dir__))
      end
    end
  end
end
