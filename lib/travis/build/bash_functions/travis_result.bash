#!/bin/bash

travis_result() {
  local result="${1}"
  export TRAVIS_TEST_RESULT=$((${TRAVIS_TEST_RESULT:-0} | $((result != 0))))

  if [[ "${result}" -eq 0 ]]; then
    echo -e "\\n${ANSI_GREEN}The command \"${TRAVIS_CMD}\" exited with ${result}.${ANSI_RESET}"
  else
    echo -e "\\n${ANSI_RED}The command \"${TRAVIS_CMD}\" exited with ${result}.${ANSI_RESET}"
  fi
}
