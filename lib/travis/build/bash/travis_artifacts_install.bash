travis_artifacts_install() {
  local source="https://s3.amazonaws.com/travis-ci-gmbh/artifacts/stable/build/${TRAVIS_OS_NAME}/${TRAVIS_ARCH}/artifacts"
  local target="${TRAVIS_HOME}/bin/artifacts"

  if [[ ${TRAVIS_OS_NAME} == "windows" ]]; then
    source="${source}.exe"
  fi

  mkdir -p "$(dirname "${target}")"
  travis_download "${source}" "${target}"
  chmod +x "${target}"
  PATH="$(dirname "${target}"):$PATH" artifacts -v
}
