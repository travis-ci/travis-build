module Travis
  class Build

    # Models an event, knowing how to construct an event name and namespace.
    class Event

      # Not sure why I decided to have a factory here. It carries the build id
      # from the payload that we currently build.
      #
      # TODO might want to remove this.
      class Factory
        attr_reader :id

        def initialize(payload)
          @id = payload[:build][:id] rescue nil
        end

        def create(type, object, data)
          Event.new(type, object, { :id => id }.merge(data))
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
