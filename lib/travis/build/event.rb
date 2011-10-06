module Travis
  module Build
    class Event
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
