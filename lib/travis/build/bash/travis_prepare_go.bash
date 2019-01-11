travis_prepare_go() {
  local gimme_url="${1}"
  local default_go_version="${2}"

  unset gvm
  if [[ -d "${TRAVIS_HOME}/.gvm" ]]; then
    mv "${TRAVIS_HOME}/.gvm" "${TRAVIS_HOME}/.gvm.disabled"
  fi

  export PATH="${TRAVIS_HOME}/bin:${PATH}"

  local gimme_version
  gimme_version="$(gimme --version &>/dev/null || echo 0)"

  if [[ "$(travis_vers2int "${gimme_version}")" > "$(travis_vers2int "1.5.2")" ]]; then
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

  # install bootstrap version so that tip/master/whatever can be used
  # immediately, then update the cache of known versions
  gimme "${default_go_version}" &>/dev/null
  gimme -k &>/dev/null
}
