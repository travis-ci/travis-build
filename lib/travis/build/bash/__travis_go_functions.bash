__travis_go_ensure_resolved() {
  if [[ "${GIMME_GO_VERSION}" ]] &&
    [[ "${_TRAVIS_RESOLVED_GIMME_GO_VERSION}" ]] &&
    [[ "${GIMME_GO_VERSION}" == "${_TRAVIS_RESOLVED_GIMME_GO_VERSION}" ]]; then
    return
  fi

  export GIMME_GO_VERSION

  local go_version
  go_version="$(gimme -r)"
  go_version="${go_version#go}"

  export _TRAVIS_RESOLVED_GIMME_GO_VERSION="${go_version}"
  export GIMME_GO_VERSION="${go_version}"

  _TRAVIS_RESOLVED_GIMME_GO_VERSION_INT="$(travis_vers2int "${go_version}")"
  export _TRAVIS_RESOLVED_GIMME_GO_VERSION_INT
}

__travis_go_fetch_godep() {
  local godep="${TRAVIS_HOME}/gopath/bin/godep"

  mkdir -p "${TRAVIS_HOME}/gopath/bin"

  case "${TRAVIS_OS_NAME}" in
  osx)
    travis_download \
      "https://${TRAVIS_APP_HOST}/files/godep_darwin_amd64" "${godep}" ||
      travis_cmd go\ get\ github.com/tools/godep --echo -retry --timing --assert
    ;;
  linux)
    travis_download \
      "https://${TRAVIS_APP_HOST}/files/godep_linux_amd64" "${godep}" ||
      travis_cmd go\ get\ github.com/tools/godep --echo -retry --timing --assert
    ;;
  esac

  chmod +x "${godep}"
}

__travis_go_handle_godep_usage() {
  if [[ ! -f "${TRAVIS_BUILD_DIR}/Godeps/Godeps.json" ]]; then
    return
  fi

  travis_cmd "export GOPATH=\"${TRAVIS_BUILD_DIR}/Godeps/_workspace:${GOPATH}\""
  travis_cmd "export PATH=\"${TRAVIS_BUILD_DIR}/Godeps/_workspace/bin:${PATH}\""

  if [[ ! -d "${TRAVIS_BUILD_DIR}/Godeps/_workspace/src" ]]; then
    __travis_go_fetch_godep
    travis_cmd godep\ restore --retry --timing --assert --echo
  fi
}
