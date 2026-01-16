function travis_wait_for_port() {
  local port
  local timeout
  local timer

  port=$1
  shift
  if [[ -z $port ]]; then
    printf "%sPort not given%s\\n" "${ANSI_RED}" "${ANSI_RESET}"
    return 1
  fi
  timeout=$1
  shift
  if [[ -z $timeout ]]; then
    timeout=10
  fi

  timer=0

  while ((timer < timeout)); do
    if ! ruby -rsocket -e "TCPSocket.new('localhost', $port)" >&/dev/null; then
      sleep 1
      ((timer = timer + 1))
    else
      break
    fi
  done

  if ((timer >= timeout)); then
    # it failed
    printf "%sFailed to connect to port %s within %s seconds%s\\n" "${ANSI_RED}" "${port}" "${timeout}" "${ANSI_RESET}"
    return 1
  fi
}
