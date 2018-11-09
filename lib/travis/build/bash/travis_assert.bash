travis_assert() {
  local result="${1:-${?}}"
  if [[ "${result}" -ne 0 ]]; then
    echo -e "${ANSI_RED}The command \"${TRAVIS_CMD}\" failed and exited with ${result} during ${TRAVIS_STAGE}.${ANSI_RESET}\\n\\nYour build has been stopped."
    travis_terminate 2
  fi
}
