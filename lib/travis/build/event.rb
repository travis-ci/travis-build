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
        "#{object.class.name.gsub('Travis::Build::', '').gsub('::', ':').downcase}:#{type}"
      end
    end
  end
end
