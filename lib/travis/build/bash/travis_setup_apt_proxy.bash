travis_setup_apt_proxy() {
  if [[ ! "${TRAVIS_APT_PROXY}" ]]; then
    return
  fi

  local dest_dir='/etc/apt/apt.conf.d'

  if [[ ! -d "${dest_dir}" ]]; then
    return
  fi

  if ! sudo -n echo &>/dev/null; then
    return
  fi

  if ! curl --connect-timeout 5 -fsSL -o /dev/null \
    "${TRAVIS_APT_PROXY}/__squignix_health__" &>/dev/null; then
    return
  fi

  (
    cat <<EOCONF
Acquire::http::Proxy "${TRAVIS_APT_PROXY}";
Acquire::https::Proxy false;
Acquire::http::Proxy::download.oracle.com "DIRECT";
Acquire::https::Proxy::download.oracle.com "DIRECT";
Acquire::http::Proxy::*.java.net "DIRECT";
Acquire::https::Proxy::*.java.net "DIRECT";
EOCONF
  ) | sudo tee "${dest_dir}/99-travis-apt-proxy" &>/dev/null
}
