__travis_go_supports_modules() {
  if [[ "${go_version_int}" > "$(travis_vers2int "1.10.99")" ||
        "${go_version}" == tip ||
        "${go_version}" == master ]] &&
     [[ -f "${TRAVIS_BUILD_DIR}/go.mod" || "${GO111MODULE}" == on ]]; then
    return 1
  fi
  return 0
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
