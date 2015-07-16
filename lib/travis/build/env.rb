require 'travis/build/env/builtin'
require 'travis/build/env/config'
require 'travis/build/env/settings'
require 'travis/build/env/var'

module Travis
  module Build
    class Env
      GROUPS = [Builtin, Settings, Config]

      attr_reader :data

      def initialize(data)
        @data = data
      end

      def groups
        @groups ||= GROUPS.map { |const| const.new(self, data) }
      end

      def announce?
        groups.any?(&:announce?)
      end

      def secure_env_vars?
        data.secure_env? && groups.reject(&:builtin?).any?(&:secure_vars?)
      end
    end
  end
end
