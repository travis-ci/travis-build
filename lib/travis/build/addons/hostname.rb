module Travis
  module Build
    class Addons
      class Hostname < Base
        def after_prepare
          sh.echo "Set hostname to #{hostname}", ansi: :yellow
          sh.cmd "sudo hostname #{hostname}", echo: true
        end

        def hostname
          config.to_s.shellescape
        end
      end
    end
  end
end
