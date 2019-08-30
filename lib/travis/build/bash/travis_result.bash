travis_result() {
  local result="${1}"
  export TRAVIS_TEST_RESULT=$((${TRAVIS_TEST_RESULT:-0} | $((result != 0))))

  if [[ "${result}" -eq 0 ]]; then
    printf "${ANSI_GREEN}The command \"%s\" exited with ${result}.${ANSI_RESET}\\n" "${TRAVIS_CMD}"
  else
    printf "${ANSI_RED}The command \"%s\" exited with ${result}.${ANSI_RESET}\\n" "${TRAVIS_CMD}"
  fi
}
