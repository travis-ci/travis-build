#!/bin/bash

travis_decrypt() {
  echo "${1}" |
    base64 -d |
    openssl rsautl -decrypt -inkey "${TRAVIS_BUILD_HOME}/.ssh/id_rsa.repo"
}
