travis_jigger() {
  local cmd_pid="${1}"
  shift
  local timeout="${1}"
  shift
  local count=0

  echo -e "\\n"

  while [[ "${count}" -lt "${timeout}" ]]; do
    count="$((count + 1))"
    echo -ne "Still running (${count} of ${timeout}): ${*}\\r"
    sleep 60
  done

  echo -e "\\n${ANSI_RED}Timeout (${timeout} minutes) reached. Terminating \"${*}\"${ANSI_RESET}\\n"
  kill -9 "${cmd_pid}"
}
