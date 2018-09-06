travis_wait() {
  local timeout="${1}"

  if [[ "${timeout}" =~ ^[0-9]+$ ]]; then
    shift
  else
    timeout=20
  fi

  local cmd=("${@}")
  local log_file="travis_wait_${$}.log"

  "${cmd[@]}" &>"${log_file}" &
  local cmd_pid="${!}"

  travis_jigger "${!}" "${timeout}" "${cmd[@]}" &
  local jigger_pid="${!}"
  local result

  {
    wait "${cmd_pid}" 2>/dev/null
    result="${?}"
    ps -p"${jigger_pid}" &>/dev/null && kill "${jigger_pid}"
  }

  if [[ "${result}" -eq 0 ]]; then
    echo -e "\\n${ANSI_GREEN}The command ${cmd[*]} exited with ${result}.${ANSI_RESET}"
  else
    echo -e "\\n${ANSI_RED}The command ${cmd[*]} exited with ${result}.${ANSI_RESET}"
  fi

  echo -e "\\n${ANSI_GREEN}Log:${ANSI_RESET}\\n"
  cat "${log_file}"

  return "${result}"
}
