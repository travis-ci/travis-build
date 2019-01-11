travis_install_go() {
  : "${GIMME_GO_VERSION:=${1}}"
  export GIMME_GO_VERSION

  local gobuild_args="${2}"

  local go_version
  go_version="$(gimme -r)"
  go_version="${go_version#go}"

  local go_version_int
  go_version_int="$(travis_vers2int "${go_version}")"

  if [[ "${go_version_int}" > "$(travis_vers2int "1.10.99")" || "${go_version}" == tip || "${go_version}" == master ]] &&
    [[ -f go.mod || "${GO111MODULE}" == on ]]; then
    echo 'Using Go 1.11+ Modules'
  elif [[ "${go_version_int}" > "$(travis_vers2int "1.4.99")" ]]; then
    echo 'Using Go 1.5 Vendoring, not checking for Godeps'
  else
    if [[ -f Godeps/Godeps.json ]]; then
      travis_cmd export\ GOPATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace:${GOPATH}"
      travis_cmd export\ PATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace/bin:${PATH}"

      if [[ "${go_version}" != go1 && "${go_version_int}" > "$(travis_vers2int "1.1.99")" ]]; then
        if [[ ! -d "Godeps/_workspace/src" ]]; then
          __travis_install_go_fetch_godep
          travis_cmd godep\ restore --retry --timing --assert --echo
        fi
      fi
    fi
  fi

  if [[ -f GNUmakefile || -f makefile || -f Makefile || -f BSDmakefile ]]; then
    echo 'Makefile detected'
  else
    travis_cmd "go get ${gobuild_args} ./..." --retry
  fi
}

__travis_install_go_fetch_godep() {
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
