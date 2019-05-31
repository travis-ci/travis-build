module Travis
  module Build
    class Script
      class Workspace
        attr_accessor :name, :paths, :type

        def initialize name, paths, type
          @name = name
          @paths = Array(paths)
          @type = type
        end


      end
    end
  end
end
