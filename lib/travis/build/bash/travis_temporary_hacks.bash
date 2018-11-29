travis_temporary_hacks() {
  if [[ ! "${TRAVIS_OS_NAME}" ]]; then
    return
  fi

  "_travis_temporary_hacks_${TRAVIS_OS_NAME}" &>/dev/null || true
}

_travis_temporary_hacks_linux() {
  for troublesome_source in \
    rabbitmq-source.list \
    travis_ci_zeromq3.list \
    neo4j.list; do
    sudo rm -f "${TRAVIS_ROOT}/etc/apt/sources.list.d/${troublesome_source}"
  done
}
