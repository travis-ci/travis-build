travis_export_go() {
  if [[ ! "${1}" ]]; then
    echo 'Missing go version positional argument' >&2
    return 86
  fi
  export TRAVIS_GO_VERSION="${1}"
  export GIMME_GO_VERSION="${TRAVIS_GO_VERSION}"
  : "${GOMAXPROCS:=2}"
  export GOMAXPROCS
}
