travis_cmd() {
  local assert output display retry timing cmd result secure

  cmd="${1}"
  export TRAVIS_CMD="${cmd}"
  shift

  while true; do
    case "${1}" in
    --assert)
      assert=true
      shift
      ;;
    --echo)
      output=true
      shift
      ;;
    --display)
      display="${2}"
      shift 2
      ;;
    --retry)
      retry=true
      shift
      ;;
    --timing)
      timing=true
      shift
      ;;
    --secure)
      secure=" 2>/dev/null"
      shift
      ;;
    *) break ;;
    esac
  done

  if [[ -n "${timing}" ]]; then
    travis_time_start
  fi

  if [[ -n "${output}" ]]; then
    echo "\$ ${display:-${cmd}}"
  fi

  if [[ -n "${retry}" ]]; then
    travis_retry eval "${cmd} ${secure}"
    result="${?}"
  else
    if [[ -n "${secure}" ]]; then
      eval "${cmd} ${secure}" 2>/dev/null
    else
      eval "${cmd} ${secure}"
    fi
    result="${?}"
    if [[ -n "${secure}" && "${result}" -ne 0 ]]; then
      echo -e "${ANSI_RED}The previous command failed, possibly due to a malformed secure environment variable.${ANSI_CLEAR}
${ANSI_RED}Please be sure to escape special characters such as ' ' and '$'.${ANSI_CLEAR}
${ANSI_RED}For more information, see https://docs.travis-ci.com/user/encryption-keys.${ANSI_CLEAR}"
    fi
  fi

  if [[ -n "${timing}" ]]; then
    travis_time_finish
  fi

  if [[ -n "${assert}" ]]; then
    travis_assert "${result}"
  fi

  return "${result}"
}
