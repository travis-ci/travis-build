require 'travis/build/appliances/agent'
require 'travis/build/appliances/check_unsupported'
require 'travis/build/appliances/checkout'
require 'travis/build/appliances/clean_up_path'
require 'travis/build/appliances/redefine_curl'
require 'travis/build/appliances/debug_tools'
require 'travis/build/appliances/deprecate_xcode_64'
require 'travis/build/appliances/deprecations'
require 'travis/build/appliances/disable_sudo'
require 'travis/build/appliances/disable_initramfs'
require 'travis/build/appliances/disable_ssh_roaming'
require 'travis/build/appliances/disable_windows_defender'
require 'travis/build/appliances/enable_i386'
require 'travis/build/appliances/env'
require 'travis/build/appliances/etc_hosts_pinning'
require 'travis/build/appliances/fix_wwdr_certificate'
require 'travis/build/appliances/rm_riak_source'
require 'travis/build/appliances/fix_rwky_redis'
require 'travis/build/appliances/update_glibc'
require 'travis/build/appliances/update_libssl'
require 'travis/build/appliances/fix_etc_hosts'
require 'travis/build/appliances/no_ipv6_localhost'
require 'travis/build/appliances/fix_container_based_trusty'
require 'travis/build/appliances/fix_sudo_enabled_trusty'
require 'travis/build/appliances/fix_etc_mavenrc'
require 'travis/build/appliances/fix_ps4'
require 'travis/build/appliances/fix_resolv_conf'
require 'travis/build/appliances/fix_mvn_settings_xml'
require 'travis/build/appliances/git_v2'
require 'travis/build/appliances/home_paths'
require 'travis/build/appliances/put_localhost_first'
require 'travis/build/appliances/update_apt_keys'
require 'travis/build/appliances/fix_hhvm_source'
require 'travis/build/appliances/rm_etc_boto_cfg'
require 'travis/build/appliances/rm_oraclejdk8_symlink'
require 'travis/build/appliances/rvm_use'
require 'travis/build/appliances/services'
require 'travis/build/appliances/show_system_info'
require 'travis/build/appliances/set_docker_mtu'
require 'travis/build/appliances/set_x'
require 'travis/build/appliances/setup_filter'
require 'travis/build/appliances/shell_session_update'
require 'travis/build/appliances/nonblock_pipe'
require 'travis/build/appliances/validate'
require 'travis/build/appliances/npm_registry'
require 'travis/build/appliances/uninstall_oclint'
require 'travis/build/appliances/update_rubygems'
require 'travis/build/appliances/update_mongo_arch'
require 'travis/build/appliances/update_heroku'
require 'travis/build/appliances/apt_get_update'
require 'travis/build/appliances/no_world_writable_dirs'
require 'travis/build/appliances/ensure_path_components'
require 'travis/build/appliances/wait_for_network'
require 'travis/build/appliances/resolvconf'
require 'travis/build/appliances/maven_central_mirror'
require 'travis/build/appliances/maven_https'

module Travis
  module Build
    module Appliances
      attr_reader :app

      def apply(name)
        @app = appliance(name)
        with_timer(name) { app.apply } if app.apply?
      end

      def appliance(name)
        Appliances.const_get(name.to_s.camelize).new(self)
      end

      def with_timer(name)
        sh.raw "travis_time_start" if app.time?
        val = yield
        sh.raw "travis_time_finish #{name}" if app.time?
        val
      end
    end
  end
end
