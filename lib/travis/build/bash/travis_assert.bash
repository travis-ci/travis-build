travis_assert() {
  local result="${1:-${?}}"
  if [[ "${result}" -ne 0 ]]; then
    printf "${ANSI_RED}The command \"%s\" failed and exited with ${result} during %s.${ANSI_RESET}\\n" "${TRAVIS_CMD}" "${TRAVIS_STAGE}"
    printf "\\nYour build has been stopped.\\n"
    travis_terminate 2
  fi
}
