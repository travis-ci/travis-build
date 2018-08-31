require 'ostruct'

module Travis
  module Build
    module Template
      class Template < OpenStruct
        def render(name, basedir: nil)
          name = "#{name}.erb.bash" if name.count('.').zero?
          name = File.expand_path(name, basedir) unless basedir.nil?
          @filename = name
          ERB.new(File.read(name)).result(binding)
        end

        attr_reader :filename

        def dirname
          File.dirname(filename)
        end

        def partial(name)
          Template.new.render(name, basedir: dirname)
        end
      end

      def template(name, vars = {})
        Template.new(vars).render(name, basedir: self.class::TEMPLATES_PATH)
      end
    end
  end
end
