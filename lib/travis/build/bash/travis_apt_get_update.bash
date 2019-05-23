travis_apt_get_update() {
  if ! command -v apt-get &>/dev/null; then
    return
  fi

  local logdest="${TRAVIS_HOME}/apt-get-update.log"
  local opts='-yq'
  if [[ "${1}" == debug ]]; then
    opts=''
    logdest='/dev/stderr'
  fi

  sudo rm -rf "${TRAVIS_ROOT}/var/lib/apt/lists/"*
  sudo apt-get update ${opts} 2>&1 | tee -a "${logdest}" &>/dev/null
}
