travis_preamble() {
  if [[ -s "${TRAVIS_BUILD_ROOT}/etc/profile" ]]; then
    # shellcheck source=/dev/null
    source "${TRAVIS_BUILD_ROOT}/etc/profile"
  fi

  if [[ -s "${TRAVIS_BUILD_HOME}/.bash_profile" ]]; then
    # shellcheck source=/dev/null
    source "${TRAVIS_BUILD_HOME}/.bash_profile"
  fi

  echo "source ${TRAVIS_BUILD_HOME}/.travis/job_stages" >>"${TRAVIS_BUILD_HOME}/.bashrc"

  mkdir -p "${TRAVIS_BUILD_HOME}/.travis"

  mkdir -p "${TRAVIS_BUILD_DIR}"
  cd "${TRAVIS_BUILD_DIR}" || exit 86
}
