travis_install_go_dependencies() {
  : "${GIMME_GO_VERSION:=${1}}"
  export GIMME_GO_VERSION

  local gobuild_args
  IFS=" " read -r -a gobuild_args <<<"${2}"

  if __travis_go_uses_modules; then
    echo 'Using Go 1.11+ Modules'
  elif __travis_go_supports_vendoring; then
    echo 'Using Go 1.5 Vendoring, not checking for Godeps'
  else
    if [[ -f "${TRAVIS_BUILD_DIR}/Godeps/Godeps.json" ]]; then
      travis_cmd export\ GOPATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace:${GOPATH}"
      travis_cmd export\ PATH="${TRAVIS_BUILD_DIR}/Godeps/_workspace/bin:${PATH}"

      if __travis_go_supports_godep; then
        if [[ ! -d "${TRAVIS_BUILD_DIR}/Godeps/_workspace/src" ]]; then
          __travis_go_fetch_godep
          travis_cmd godep\ restore --retry --timing --assert --echo
        fi
      fi
    fi
  fi

  if travis_has_makefile; then
    echo 'Makefile detected'
  else
    local has_t
    for arg in "${gobuild_args[@]}"; do
      if [[ "${arg}" == "-t" ]]; then
        has_t=1
      fi
    done

    if [[ ! "${has_t}" ]]; then
      gobuild_args=("${gobuild_args[@]}" -t)
    fi

    travis_cmd "go get ${gobuild_args[*]} ./..." --retry
  fi
}
