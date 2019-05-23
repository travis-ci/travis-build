travis_has_makefile() {
  : "${TRAVIS_BUILD_DIR:=.}"
  if [[ -f "${TRAVIS_BUILD_DIR}/GNUmakefile" || -f "${TRAVIS_BUILD_DIR}/makefile" || -f "${TRAVIS_BUILD_DIR}/Makefile" || -f "${TRAVIS_BUILD_DIR}/BSDmakefile" ]]; then
    return 0
  fi
  return 1
}
