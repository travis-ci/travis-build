module Travis
  module Build
    module BashScripts
      def bash_script(name)
        File.read(expanded_bash_script_name(name)).untaint
      end

      private def expanded_bash_script_name(name)
        File.expand_path("./bash_scripts/#{name}.bash", __dir__)
      end
    end
  end
end
