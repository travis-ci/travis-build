require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateRubygems < Base
        BUNDLER_BASELINE_VERSION='1.15.4'
        RUBYGEMS_BASELINE_VERSION='2.6.13'
        def apply
          sh.cmd %q:cat >$HOME/.rvm/hooks/after_use <<EORVMHOOK
gem --help >&/dev/null || return 0

vers2int() {
  printf '1%%03d%%03d%%03d%%03d' \$(echo "\$1" | tr '.' ' ')
}

if [[ \$(vers2int \`gem --version\`) -lt \$(vers2int "%s") ]]; then
  echo ""
  echo "** Updating RubyGems to the latest version for security reasons. **"
  echo "** If you need an older version, you can downgrade with 'gem update --system OLD_VERSION'. **"
  echo ""
  gem update --system

  if [[ \$(vers2int \`bundle --version | awk '{print \$NF}'\`) -lt \$(vers2int "%s") ]]; then
    echo ""
    echo "** Updating Bundler to coincide with RubyGems update. **"
    echo "** If you need an older version, you can downgrade with 'gem uninstall -ax bundler; gem install bundler -v OLD_VERSION'. **"
    echo ""
    gem update bundler
  fi
fi
EORVMHOOK
: % [RUBYGEMS_BASELINE_VERSION, BUNDLER_BASELINE_VERSION]
          sh.cmd "chmod +x $HOME/.rvm/hooks/after_use"
        end
      end
    end
  end
end
