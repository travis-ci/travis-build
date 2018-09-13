travis_decrypt() {
  echo "${1}" |
    base64 -d |
    openssl rsautl -decrypt -inkey "${TRAVIS_HOME}/.ssh/id_rsa.repo"
}

decrypt() {
  travis_decrypt "${@}"
}
