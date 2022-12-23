#frozen_string_literal: true
module Travis
  module Vcs
    class Base
      attr_reader :sh, :data

      def self.top
        raise NotImplementedError
      end

      def self.version
        raise NotImplementedError
      end

      def self.paths
        raise NotImplementedError
      end

      def self.defaults
        raise NotImplementedError
      end

      def initialize(sh, data)
          @sh = sh
          @data = data
      end

      def checkout
        raise NotImplementedError
      end

    end
  end
end
