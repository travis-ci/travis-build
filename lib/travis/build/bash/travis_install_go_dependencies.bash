travis_install_go_dependencies() {
  : "${GIMME_GO_VERSION:=${1}}"
  export GIMME_GO_VERSION

  local gobuild_args="${2}"

  local go_version
  go_version="$(gimme -r)"
  go_version="${go_version#go}"

  local go_version_int
  go_version_int="$(travis_vers2int "${go_version}")"

  if __travis_go_supports_modules; then
    echo 'Using Go 1.11+ Modules'
  elif [[ "${go_version_int}" > "$(travis_vers2int "1.4.99")" ]]; then
    echo 'Using Go 1.5 Vendoring, not checking for Godeps'
  else
    if [[ -f Godeps/Godeps.json ]]; then
      travis_cmd export\ GOPATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace:${GOPATH}"
      travis_cmd export\ PATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace/bin:${PATH}"

      if [[ "${go_version}" != go1 && "${go_version_int}" > "$(travis_vers2int "1.1.99")" ]]; then
        if [[ ! -d "Godeps/_workspace/src" ]]; then
          __travis_go_fetch_godep
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
