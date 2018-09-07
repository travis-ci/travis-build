travis_apt_get_update() {
  if ! command -v apt-get &>/dev/null; then
    return
  fi

  local opts='-qq &>/dev/null'
  if [[ "${1}" == debug ]]; then
    opts=''
  fi

  sudo rm -rf "${TRAVIS_BUILD_ROOT}/var/lib/apt/lists/"*
  sudo apt-get update ${opts}
}
