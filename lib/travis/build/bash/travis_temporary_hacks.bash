travis_temporary_hacks() {
  for troublesome_source in \
    rabbitmq-source.list \
    neo4j.list; do
    sudo rm -f "${TRAVIS_BUILD_ROOT}/etc/apt/sources.list.d/${troublesome_source}"
  done
}
