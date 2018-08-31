export ANSI_RED="\033[31;1m"
export ANSI_GREEN="\033[32;1m"
export ANSI_YELLOW="\033[33;1m"
export ANSI_RESET="\033[0m"
export ANSI_CLEAR="\033[0K"

if [ "${TERM}" = dumb ]; then
  unset TERM
fi
: "${SHELL:=/bin/bash}"
: "${TERM:=xterm}"
: "${USER:=travis}"
export SHELL
export TERM
export USER

case $(uname | tr '[A-Z]' '[a-z]') in
  linux)
    export TRAVIS_OS_NAME=linux
    ;;
  darwin)
    export TRAVIS_OS_NAME=osx
    ;;
  *)
    export TRAVIS_OS_NAME=notset
    ;;
esac

export TRAVIS_DIST=notset
export TRAVIS_INIT=notset
TRAVIS_ARCH="$(uname -m)"
if [[ "${TRAVIS_ARCH}" == x86_64 ]]; then
  TRAVIS_ARCH='amd64'
fi
export TRAVIS_ARCH

if [[ "${TRAVIS_OS_NAME}" == linux ]]; then
  export TRAVIS_DIST="$(lsb_release -sc 2>/dev/null || echo notset)"
  if command -v systemctl >/dev/null 2>&1; then
    export TRAVIS_INIT=systemd
  else
    export TRAVIS_INIT=upstart
  fi
fi

TRAVIS_TEST_RESULT=
TRAVIS_CMD=

TRAVIS_TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'travis_tmp')"
if command -v pgrep &>/dev/null; then
  pgrep -u "${USER}" | grep -v -w $$ >"${TRAVIS_TMPDIR}/pids_before"
fi

travis_cmd() {
  local assert output display retry timing cmd result secure

  cmd="${1}"
  TRAVIS_CMD="${cmd}"
  shift

  while true; do
    case "${1}" in
      --assert)  assert=true; shift ;;
      --echo)    output=true; shift ;;
      --display) display="${2}";  shift 2;;
      --retry)   retry=true;  shift ;;
      --timing)  timing=true; shift ;;
      --secure)  secure=" 2>/dev/null"; shift ;;
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

travis_time_start() {
  TRAVIS_TIMER_ID="$(printf %08x $(( RANDOM * RANDOM )))"
  TRAVIS_TIMER_START_TIME="$(travis_nanoseconds)"
  export TRAVIS_TIMER_ID TRAVIS_TIMER_START_TIME
  echo -en "travis_time:start:$TRAVIS_TIMER_ID\r${ANSI_CLEAR}"
}

travis_time_finish() {
  local result="${?}"
  local travis_timer_end_time
  travis_timer_end_time="$(travis_nanoseconds)"
  local duration
  duration="$((${travis_timer_end_time}-${TRAVIS_TIMER_START_TIME}))"
  echo -en "\ntravis_time:end:${TRAVIS_TIMER_ID}:start=${TRAVIS_TIMER_START_TIME},finish=${travis_timer_end_time},duration=${duration}\r${ANSI_CLEAR}"
  return "${result}"
}

travis_trace_span() {
  local result="${?}"
  local template="${1}"
  local timestamp
  timestamp="$(travis_nanoseconds)"
  template="${template/__TRAVIS_TIMESTAMP__/${timestamp}}"
  template="${template/__TRAVIS_STATUS__/${result}}"
  echo "${template}" >> /tmp/build.trace
}

travis_nanoseconds() {
  local cmd='date'
  local format='+%s%N'

  if hash gdate > /dev/null 2>&1; then
    <%# use gdate if available %>
    cmd='gdate'
  elif [[ "${TRAVIS_OS_NAME}" == osx ]]; then
    <%# fallback to second precision on darwin (does not support %N) %>
    format='+%s000000000'
  fi

  "${cmd}" -u "${format}"
}

travis_internal_ruby() {
  if ! type rvm &>/dev/null; then
    source "${TRAVIS_BUILD_HOME}/.rvm/scripts/rvm" &>/dev/null
  fi
  local i selected_ruby rubies_array rubies_array_sorted rubies_array_len
  rubies_array=( $(
    rvm list strings \
      | while read -r v; do
          if [[ ! "${v}" =~ ${TRAVIS_BUILD_INTERNAL_RUBY_REGEX} ]]; then
            continue
          fi
          v="${v//ruby-/}"
          v="${v%%-*}"
          echo "$(travis_vers2int "${v}")_${v}"
        done
  ) )
  travis_bash_qsort_numeric "${rubies_array[@]}"
  rubies_array_sorted=( "${travis_bash_qsort_numeric_ret[@]}" )
  rubies_array_len="${#rubies_array_sorted[@]}"
  if (( rubies_array_len <= 0 )); then
    echo 'default'
  else
    i=$(( rubies_array_len - 1 ))
    selected_ruby="${rubies_array_sorted[${i}]}"
    selected_ruby="${selected_ruby##*_}"
    echo "${selected_ruby:-default}"
  fi
}

travis_assert() {
  local result="${1:-${?}}"
  if [[ "${result}" -ne 0 ]]; then
    echo -e "\n${ANSI_RED}The command \"${TRAVIS_CMD}\" failed and exited with ${result} during ${TRAVIS_STAGE}.${ANSI_RESET}\n\nYour build has been stopped."
    travis_terminate 2
  fi
}

travis_result() {
  local result="${1}"
  export TRAVIS_TEST_RESULT=$(( ${TRAVIS_TEST_RESULT:-0} | $((${result} != 0)) ))

  if [[ "${result}" -eq 0 ]]; then
    echo -e "\n${ANSI_GREEN}The command \"${TRAVIS_CMD}\" exited with ${result}.${ANSI_RESET}"
  else
    echo -e "\n${ANSI_RED}The command \"${TRAVIS_CMD}\" exited with ${result}.${ANSI_RESET}"
  fi
}

travis_terminate() {
  set +e
  <%# Restoring the file descriptors of redirect_io filter strategy %>
  [[ "${TRAVIS_FILTERED}" = redirect_io && -e /dev/fd/9 ]] &&
    sync &&
    command exec 1>&9 2>&9 9>&- &&
    sync
  pgrep -u "${USER}" | grep -v -w "${$}" >"${TRAVIS_TMPDIR}/pids_after"
  kill $(awk 'NR==FNR{a[$1]++;next};!($1 in a)' $TRAVIS_TMPDIR/pids_{before,after}) &> /dev/null || true
  pkill -9 -P "${$}" &> /dev/null || true
  exit "${1}"
}

travis_wait() {
  local timeout="${1}"

  if [[ "${timeout}" =~ ^[0-9]+$ ]]; then
    <%# looks like an integer, so we assume it's a timeout %>
    shift
  else
    <%# default value %>
    timeout=20
  fi

  local cmd="${@}"
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
    echo -e "\n${ANSI_GREEN}The command ${cmd} exited with ${result}.${ANSI_RESET}"
  else
    echo -e "\n${ANSI_RED}The command ${cmd} exited with ${result}.${ANSI_RESET}"
  fi

  echo -e "\n${ANSI_GREEN}Log:${ANSI_RESET}\n"
  cat "${log_file}"

  return "${result}"
}

travis_jigger() {
  <%# helper method for travis_wait() %>
  local cmd_pid="${1}"
  shift
  local timeout="${1}" <%# in minutes %>
  shift
  local count=0

  <%# clear the line %>
  echo -e "\n"

  while [[ "${count}" -lt "${timeout}" ]]; do
    count="$((count + 1))"
    echo -ne "Still running (${count} of ${timeout}): ${@}\r"
    sleep 60
  done

  echo -e "\n${ANSI_RED}Timeout (${timeout} minutes) reached. Terminating \"${@}\"${ANSI_RESET}\n"
  kill -9 "${cmd_pid}"
}

travis_retry() {
  local result=0
  local count=1
  while [[ "${count}" -le 3 ]]; do
    [[ "${result}" -ne 0 ]] && {
      echo -e "\n${ANSI_RED}The command \"${@}\" failed. Retrying, ${count} of 3.${ANSI_RESET}\n" >&2
    }
    "${@}" && { result=0 && break; } || result="${?}"
    count="$((count + 1))"
    sleep 1
  done

  [[ "${count}" -gt 3 ]] && {
    echo -e "\n${ANSI_RED}The command \"${@}\" failed 3 times.${ANSI_RESET}\n" >&2
  }

  return "${result}"
}

travis_fold() {
  local action="${1}"
  local name="${2}"
  echo -en "travis_fold:${action}:${name}\r${ANSI_CLEAR}"
}

travis_download() {
  local src="${1}"
  local dst="${2}"

  if curl --version &>/dev/null; then
    curl -fsSL --connect-timeout 5 "${src}" -o "${dst}" 2>/dev/null
    return "${?}"
  fi

  if wget --version &>/dev/null; then
    wget --connect-timeout 5 -q "${src}" -O "${dst}" 2>/dev/null
    return "${?}"
  fi

  return 1
}

decrypt() {
  echo "${1}" |
    base64 -d |
    openssl rsautl -decrypt -inkey "${TRAVIS_BUILD_HOME}/.ssh/id_rsa.repo"
}

travis_vers2int() {
  printf '1%03d%03d%03d%03d' $(echo "${1}" | tr '.' ' ')
}

<%# based on http://stackoverflow.com/a/30576368 by gniourf_gniourf :heart_eyes_cat: %>
travis_bash_qsort_numeric() {
  local pivot i smaller=() larger=()
  travis_bash_qsort_numeric_ret=()
  (($#==0)) && return 0
  pivot="${1}"
  shift
  for i; do
    if [[ "${i%%_*}" -lt "${pivot%%_*}" ]]; then
      smaller+=( "${i}" )
    else
      larger+=( "${i}" )
    fi
  done
  travis_bash_qsort_numeric "${smaller[@]}"
  smaller=( "${travis_bash_qsort_numeric_ret[@]}" )
  travis_bash_qsort_numeric "${larger[@]}"
  larger=( "${travis_bash_qsort_numeric_ret[@]}" )
  travis_bash_qsort_numeric_ret=( "${smaller[@]}" "${pivot}" "${larger[@]}" )
}
