module Travis
  module Build
    module BashFunctions
      def bash_function(name)
        File.read(expanded_bash_function_name(name)).untaint
      end

      private def expanded_bash_function_name(name)
        File.expand_path("./bash_functions/#{name}.bash", __dir__)
      end
    end
  end
end
