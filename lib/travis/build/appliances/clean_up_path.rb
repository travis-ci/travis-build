require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class CleanUpPath < Base
        def apply
          sh.export 'PATH', "$(echo $PATH | sed -e 's/::/:/g')", echo: false
          sh.export 'PATH', "$(echo -n $PATH | perl -e 'print join(\":\", grep { not $seen{$_}++ } split(/:/, scalar <>))')", echo: false
        end
      end
    end
  end
end
