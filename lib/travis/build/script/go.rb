require 'uri'

module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {
          gobuild_args: '-v',
          gimme_config: {
            url: Travis::Build.config.gimme.url.output_safe
          },
          go: Travis::Build.config.go_version.output_safe
        }

        def prepare
          super
          sh.raw bash('__travis_go_functions')
          sh.raw bash('travis_has_makefile')
          sh.raw bash('travis_prepare_go')
          sh.cmd %[travis_prepare_go #{shesc(gimme_url)} #{shesc(DEFAULTS[:go])}], echo: false
        end

        def export
          sh.raw bash('travis_export_go')
          sh.cmd %[travis_export_go #{shesc(go_version)} #{shesc(go_import_path)}], echo: true
          super
        end

        def setup
          sh.raw bash('travis_setup_go')
          sh.cmd 'travis_setup_go'
          super
        end

        def announce
          super
          sh.cmd 'gimme version'
          sh.cmd 'go version'
          sh.cmd 'go env', fold: 'go.env'
        end

        def install
          sh.raw bash('travis_install_go_dependencies')
          sh.cmd "travis_install_go_dependencies #{go_version} #{shesc(gobuild_args)}", fold: 'install'
        end

        def script
          sh.raw bash('travis_script_go')
          sh.cmd "travis_script_go #{shesc(gobuild_args)}"
        end

        def cache_slug
          super << '--go-' << go_version
        end

        private def gobuild_args
          config[:gobuild_args]
        end

        private def go_import_path
          config[:go_import_path] || "#{data.source_host}/#{data.slug}"
        end

        private def go_version
          @go_version ||= normalized_go_version
        end

        private def normalized_go_version
          v = Array(config[:go]).first.to_s
          return v if v == 'go1'
          v.sub(/^go/, '')
        end

        private def gimme_config
          config[:gimme_config]
        end

        private def gimme_url
          cleaned = URI.parse(gimme_config[:url]).to_s.output_safe
          return cleaned if cleaned =~ %r{^https://raw\.githubusercontent\.com/travis-ci/gimme}
          DEFAULTS[:gimme_config][:url]
        rescue URI::InvalidURIError => e
          warn e
          DEFAULTS[:gimme_config][:url]
        end
      end
    end
  end
end
