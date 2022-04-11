require 'travis/vcs/base.rb'
require 'travis/vcs/git.rb'
require 'travis/vcs/perforce.rb'
require 'travis/vcs/svn.rb'
require 'travis/build/errors.rb'

module Travis
  module Vcs
    class <<self
      def top
        "Travis::Vcs::#{provider_name.to_s.camelize}".constantize.top
      rescue NameError
        raise Travis::Build::UnknownServiceTypeError.new provider_name
      end

      def version
        "Travis::Vcs::#{provider_name.to_s.camelize}".constantize.version
      rescue NameError
        raise Travis::Build::UnknownServiceTypeError.new provider_name
      end

      def paths
        "Travis::Vcs::#{provider_name.to_s.camelize}".constantize.paths
      rescue NameError
        raise Travis::Build::UnknownServiceTypeError.new(provider_name)
      end

      def clone_cmd(endpoint, source)
        "Travis::Vcs::#{provider_name.to_s.camelize}".constantize.clone_cmd(endpoint, source)
      rescue NameError
        raise Travis::Build::UnknownServiceTypeError.new provider_name
      end

      def checkout_cmd(branch)
        "Travis::Vcs::#{provider_name.to_s.camelize}".constantize.checkout_cmd(branch)
      rescue NameError
        raise Travis::Build::UnknownServiceTypeError.new(provider_name)
      end

      def revision_cmd
        "Travis::Vcs::#{provider_name.to_s.camelize}".constantize.revision_cmd
      rescue NameError
        raise Travis::Build::UnknownServiceTypeError.new provider_name
      end

      def checkout(sh,data)
        vcs(sh,data).checkout
      end

      def defaults(server_type)
        @provider_name = server_type
        "Travis::Vcs::#{provider_name.to_s.camelize}".constantize.defaults
      rescue NameError
        raise Travis::Build::UnknownServiceTypeError.new provider_name
      end

      private
      def vcs(sh,data)
        provider = data[:repository][:server_type] if data.key?(:repository)
        provider = provider_name unless provider
        @provider_name = provider
        "Travis::Vcs::#{provider.to_s.camelize}".constantize.new(sh,data)
      rescue NameError
        raise Travis::Build::UnknownServiceTypeError.new provider_name
      end

      def provider_name
        @provider_name ||= 'git'
      end
      end
  end
end
