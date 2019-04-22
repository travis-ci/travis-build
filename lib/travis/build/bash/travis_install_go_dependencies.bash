travis_install_go_dependencies() {
  : "${GIMME_GO_VERSION:=${1}}"
  export GIMME_GO_VERSION

  local gobuild_args
  IFS=" " read -r -a gobuild_args <<<"${2}"

  __travis_go_handle_godep_usage

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
