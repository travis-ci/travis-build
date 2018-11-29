travis_result() {
  local result="${1}"
  export TRAVIS_TEST_RESULT=$((${TRAVIS_TEST_RESULT:-0} | $((result != 0))))

  if [[ "${result}" -eq 0 ]]; then
    echo -e "${ANSI_GREEN}The command \"${TRAVIS_CMD}\" exited with ${result}.${ANSI_RESET}\\n"
  else
    echo -e "${ANSI_RED}The command \"${TRAVIS_CMD}\" exited with ${result}.${ANSI_RESET}\\n"
  fi
}
