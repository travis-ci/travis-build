travis_export_go() {
  if [[ ! "${1}" ]]; then
    echo 'Missing go version positional argument' >&2
    return 86
  fi

  if [[ ! "${2}" ]]; then
    echo 'Missing go import path positional argument' >&2
    return 86
  fi

  export TRAVIS_GO_VERSION="${1}"
  export TRAVIS_GO_IMPORT_PATH="${2}"

  export GIMME_GO_VERSION="${TRAVIS_GO_VERSION}"
  : "${GOMAXPROCS:=$(nproc 2>/dev/null || echo 2)}"
  export GOMAXPROCS

  : "${GO111MODULE:=auto}"
  export GO111MODULE
}
