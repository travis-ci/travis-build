travis_prepare_go() {
  local gimme_url="${1}"
  local default_go_version="${2}"

  if [[ ! "${gimme_url}" ]]; then
    echo 'Missing gimme_url positional argument' >&2
    return 86
  fi

  if [[ ! "${default_go_version}" ]]; then
    echo 'Missing default_go_version positional argument' >&2
    return 86
  fi

  unset gvm
  if [[ -d "${TRAVIS_HOME}/.gvm" ]]; then
    mv "${TRAVIS_HOME}/.gvm" "${TRAVIS_HOME}/.gvm.disabled"
  fi

  export PATH="${TRAVIS_HOME}/bin:${PATH}"

  local gimme_version
  gimme_version="$(gimme --version &>/dev/null || echo 0)"

  if [[ "$(travis_vers2int "${gimme_version#v}")" > "$(travis_vers2int "1.5.2.99")" ]]; then
    __travis_prepare_go_gimme_bootstrap "${default_go_version}"
    return
  fi

  if [[ ! "${TRAVIS_APP_HOST}" ]]; then
    echo "Installing gimme from ${gimme_url}"
    mkdir -p "${TRAVIS_HOME}/bin"
    travis_download "${gimme_url}" "${TRAVIS_HOME}/bin/gimme"
  else
    echo 'Updating gimme'
    mkdir -p "${TRAVIS_HOME}/bin"
    travis_download \
      "https://${TRAVIS_APP_HOST}/files/gimme" "${TRAVIS_HOME}/bin/gimme" ||
      travis_download "${gimme_url}" "${TRAVIS_HOME}/bin/gimme"
  fi

  chmod +x "${TRAVIS_HOME}/bin/gimme"
  __travis_prepare_go_gimme_bootstrap "${default_go_version}"
}

__travis_prepare_go_gimme_bootstrap() {
  # install bootstrap version so that tip/master/whatever can be used
  # immediately, then update the cache of known versions
  gimme "${1}" &>/dev/null
  gimme -k &>/dev/null
}
