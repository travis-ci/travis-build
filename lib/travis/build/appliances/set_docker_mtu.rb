require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class SetDockerMtu < Base
        def apply?
          linux?
        end

        def apply
          sh.fold "docker_mtu" do
            sh.raw <<-EOF
sudo test -f /etc/docker/daemon.json
if [[ $? = 0 ]]; then
  echo '[{"op":"add","path":"/mtu","value":1460}]' > mtu.jsonpatch
  sudo jsonpatch /etc/docker/daemon.json mtu.jsonpatch > daemon.json
  sudo mv daemon.json /etc/docker/daemon.json
else
  echo '{"mtu":1460}' | sudo tee /etc/docker/daemon.json > /dev/null
fi

sudo service docker restart
            EOF
          end
        end
      end
    end
  end
end
