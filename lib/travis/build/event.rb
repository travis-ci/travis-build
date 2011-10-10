module Travis
  class Build
    class Event
      class Factory
        attr_reader :id

        def initialize(payload)
          @id = payload[:id]
        end

        def create(type, object, data)
          Event.new(type, object, data.merge(:id => id))
        end
      end

      attr_reader :type, :object, :data

      def initialize(type, object, data)
        @object = object
        @type = type
        @data = data
      end

      def name
        "#{namespace}:#{type}"
      end

      protected

        def namespace
          tokens = object.class.name.downcase.split('::')
          tokens[2, 2].join(':')
        end
    end
  end
end
