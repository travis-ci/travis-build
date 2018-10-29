travis_wait_for_network() {
  local wait_retries="${1}"
  local count=0
  shift
  local urls=("${@}")

  while [[ "${count}" -lt "${wait_retries}" ]]; do
    local confirmed=0
    for url in "${urls[@]}"; do
      if travis_download "${url}" /dev/null; then
        confirmed=$((confirmed + 1))
      fi
    done

    if [[ "${#urls[@]}" -eq "${confirmed}" ]]; then
      return
    fi

    count=$((count + 1))
    sleep 1
  done

  echo -e "${ANSI_RED}Timeout waiting for network availability.${ANSI_RESET}"
}
