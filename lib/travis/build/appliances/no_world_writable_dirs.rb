require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class NoWorldWritableDirs < Base
        def apply
          sh.cmd <<-EOF
for dir in $(echo $PATH | tr : " "); do
  test -d $dir && sudo chmod o-w $dir | grep changed
done
          EOF
        end
      end
    end
  end
end
