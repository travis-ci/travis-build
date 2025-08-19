travis_terminate() {
  if [[ ! "${TRAVIS_OS_NAME}" ]]; then
    return
  fi

  _travis_terminate_agent
  "_travis_terminate_${TRAVIS_OS_NAME}" "${@}"
}

exit() {
  local code="${1:-$?}"
  # Should work as normal `exit` in subshells of the main shell.
  # In unrelated shells, this code won't be imported.
  if [ $$ -ne $BASHPID ]; then
    _travis_terminate_exit "$code"
  else
    travis_terminate "$code"
  fi
}

_travis_terminate_linux() {
  _travis_terminate_unix "${@}"
}

_travis_terminate_osx() {
  _travis_terminate_unix "${@}"
}

_travis_terminate_freebsd() {
  _travis_terminate_unix "${@}"
}

_travis_terminate_unix() {
  set +e
  [[ "${TRAVIS_FILTERED}" == redirect_io && -e /dev/fd/9 ]] &&
    sync &&
    command exec 1>&9 2>&9 9>&- &&
    sync
  pgrep -u "${USER}" | grep -v -w "${$}" >"${TRAVIS_TMPDIR}/pids_after"
  awk 'NR==FNR{a[$1]++;next};!($1 in a)' "${TRAVIS_TMPDIR}"/pids_{before,after} |
    xargs kill &>/dev/null || true
  pkill -9 -P "${$}" &>/dev/null || true
  _travis_terminate_exit "$1"
}

_travis_terminate_windows() {
  # TODO: find all child processes and exit via ... powershell?
  _travis_terminate_exit "$1"
}

_travis_terminate_exit() {
  # shellcheck disable=SC2015 # handling error of either command is intended
  declare -F exit &>/dev/null && unset -f exit || true
  exit "$1"
}

_travis_terminate_agent() {
  [ ! -f /tmp/travis/agent.pid ] && return
  pid=$(cat /tmp/travis/agent.pid)

  kill "$pid" &>/dev/null
  counter=500
  while test $((counter--)) -ne 0 -a -f /tmp/travis/agent.pid; do
    sleep 0.1
  done

  [ -z ${TRAVIS_AGENT_DEBUG+x} ] && return
  echo
  travis_fold start agent.debug
  echo 'cat /tmp/travis/agent.log'
  cat /tmp/travis/agent.log
  travis_fold end agent.debug
}
