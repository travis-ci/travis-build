module Travis
  module Build
    class Script
      module Templates
        class Template < OpenStruct
          def render(filename)
            ERB.new(File.read(filename)).result(binding)
          end
        end

        def template(name, vars = {})
          Template.new(vars).render(File.expand_path(name, self.class::TEMPLATES_PATH))
        end
      end
    end
  end
end
