travis_whereami() {
  curl -sSL -H 'Accept: text/plain' \
    "${TRAVIS_WHEREAMI_URL:-https://whereami.travis-ci.com}"
}
