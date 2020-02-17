require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class WaitForNetwork < Base
        def apply
          return unless Travis::Build.config.wait_for_network_check
          sh.raw bash('travis_wait_for_network')
          sh.cmd(
            "travis_wait_for_network #{wait_retries} #{check_urls.map(&:inspect).join(' ')}",
            echo: false
          )
        end

        private def check_urls
          @check_urls ||= Travis::Build.config.network.check_urls.map do |tmpl|
            (tmpl % {
              app_host: app_host,
              job_id: data.job[:id],
              repo: data.slug
            }).output_safe
          end
        end

        private def wait_retries
          @wait_retries ||= Integer(Travis::Build.config.network.wait_retries)
        end
      end
    end
  end
end
