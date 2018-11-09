require 'ostruct'

module Travis
  module Build
    module Template
      class Template < OpenStruct
        def render(name, basedir: nil)
          name = name.to_s
          name = File.expand_path(name, basedir) unless basedir.nil?
          ERB.new(File.read(name)).result(binding)
        end
      end

      def template(name, vars = {})
        Template.new(vars).render(name, basedir: self.class::TEMPLATES_PATH)
      end
    end
  end
end
