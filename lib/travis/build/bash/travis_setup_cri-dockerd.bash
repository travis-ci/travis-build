travis_setup_cri-dockerd() {
  local cri_containerd_cni_version='1.6.14'
  local crictl_version='v1.24.2'
  echo -e "${ANSI_YELLOW}cri-dockerd setup ${ANSI_CLEAR}"
  sudo bash -c "
    groupadd docker || true;
    apt-get update && apt-get install socat eptables;
    apt-get install conntrack containerd;
    wget https://github.com/containerd/containerd/releases/download/v${cri_containerd_cni_version}/cri-containerd-cni-${cri_containerd_cni_version}-linux-amd64.tar.gz;
    tar zxvf cri-containerd-cni-${cri_containerd_cni_version}-linux-amd64.tar.gz -C /;
    rm -rf cri-containerd-cni-1.6.14-linux-amd64.tar.gz;
    wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.0/cri-dockerd_0.3.0.3-0.ubuntu-bionic_amd64.deb;
    dpkg -i cri-dockerd_0.3.0.3-0.ubuntu-bionic_amd64.deb;
    wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/v0.3.0/packaging/systemd/cri-docker.service
    wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/v0.3.0/packaging/systemd/cri-docker.socket;
    mv cri-docker.socket cri-docker.service /etc/systemd/system/;
    systemctl daemon-reload;
    systemctl enable cri-docker.service;
    systemctl enable --now cri-docker.socket;
    wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${crictl_version}/crictl-${crictl_version}-linux-amd64.tar.gz
    tar zxvf crictl-${crictl_version}-linux-amd64.tar.gz -C /usr/bin;
    rm -f crictl-${crictl_version}-linux-amd64.tar.gz;
    echo runtime-endpoint: unix:///run/containerd/containerd.sock > /etc/crictl.yaml;
    echo image-endpoint: unix:///run/containerd/containerd.sock >> /etc/crictl.yaml;
";
}
