travis_disable_ssh_roaming() {
  mkdir -p "${TRAVIS_HOME}/.ssh"
  chmod 0700 "${TRAVIS_HOME}/.ssh"
  touch "${TRAVIS_HOME}/.ssh/config"
  ssh-keygen -R github.com
  curl -L https://api.github.com/meta | jq -r ".ssh_keys | .[]" | sed -e "s/^/github.com /" >> ~/.ssh/known_hosts
  echo -e "Host *\\n  UseRoaming no\\n" |
    cat - "${TRAVIS_HOME}/.ssh/config" >"${TRAVIS_HOME}/.ssh/config.tmp" &&
    mv "${TRAVIS_HOME}/.ssh/config.tmp" "${TRAVIS_HOME}/.ssh/config"
}
