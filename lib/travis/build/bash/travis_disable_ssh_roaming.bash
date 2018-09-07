travis_disable_ssh_roaming() {
  mkdir -p "${TRAVIS_BUILD_HOME}/.ssh"
  chmod 0700 "${TRAVIS_BUILD_HOME}/.ssh"
  touch "${TRAVIS_BUILD_HOME}/.ssh/config"
  echo -e "Host *\\n  UseRoaming no\\n" |
    cat - "${TRAVIS_BUILD_HOME}/.ssh/config" >"${TRAVIS_BUILD_HOME}/.ssh/config.tmp" &&
    mv "${TRAVIS_BUILD_HOME}/.ssh/config.tmp" "${TRAVIS_BUILD_HOME}/.ssh/config"
}
