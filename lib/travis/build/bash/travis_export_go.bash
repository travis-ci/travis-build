travis_export_go() {
  export TRAVIS_GO_VERSION="${1}"
  export GIMME_GO_VERSION="${TRAVIS_GO_VERSION}"
  : "${GOMAXPROCS:=2}"
  export GOMAXPROCS
}
