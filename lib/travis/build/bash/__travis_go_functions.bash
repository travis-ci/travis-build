__travis_go_supports_modules() {
  __travis_go_ensure_resolved

  local gv_int="${_TRAVIS_RESOLVED_GIMME_GO_VERSION_INT}"
  local gv="${_TRAVIS_RESOLVED_GIMME_GO_VERSION}"

  if [[ "${gv_int}" > "$(travis_vers2int "1.10.99")" || "${gv}" == tip || "${gv}" == master ]] &&
    [[ -f "${TRAVIS_BUILD_DIR}/go.mod" || "${GO111MODULE}" == on ]]; then
    return 1
  fi
  return 0
}

__travis_go_supports_vendoring() {
  __travis_go_ensure_resolved

  if [[ "${_TRAVIS_RESOLVED_GIMME_GO_VERSION_INT}" > "$(travis_vers2int "1.4.99")" ]]; then
    return 1
  fi
  return 0
}

__travis_go_supports_godep() {
  __travis_go_ensure_resolved

  local gv_int="${_TRAVIS_RESOLVED_GIMME_GO_VERSION_INT}"
  local gv="${_TRAVIS_RESOLVED_GIMME_GO_VERSION}"

  if [[ "${gv}" != go1 && "${gv_int}" > "$(travis_vers2int "1.1.99")" ]]; then
    return 1
  fi
  return 0
}

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

  if [[ "${TRAVIS_OS_NAME}" == osx ]]; then
    travis_download \
      "https://${TRAVIS_APP_HOST}/files/godep_darwin_amd64" "${godep}" ||
      travis_cmd go\ get\ github.com/tools/godep --echo -retry --timing --assert
  elif [[ "${TRAVIS_OS_NAME}" == linux ]]; then
    travis_download \
      "https://${TRAVIS_APP_HOST}/files/godep_linux_amd64" "${godep}" ||
      travis_cmd go\ get\ github.com/tools/godep --echo -retry --timing --assert
  fi

  chmod +x "${godep}"
}
