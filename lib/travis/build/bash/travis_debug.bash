#!/bin/bash
# shellcheck disable=SC1117
set -o errexit

export ANSI_RED="\033[31;1m"
export ANSI_GREEN="\033[32;1m"
export ANSI_YELLOW="\033[33;1m"
export ANSI_BLUE="\033[34;1m"
export ANSI_RESET="\033[0m"
export ANSI_CLEAR="\033[0K"

travis_debug_warn() {
  echo -e "${ANSI_YELLOW}travis_debug: $1${ANSI_RESET}" 1>&2
}

main() {
  local QUIET TMATE TMATE_MSG
  export TMATE="tmate -S /tmp/tmate.sock"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -q | --quiet)
      QUIET=1
      shift
      ;;
    *)
      travis_debug_warn "Unknown argument: $1"
      shift
      ;;
    esac
  done

  TMATE_MSG="
  Run individual commands; or execute configured build phases
  with ${ANSI_BLUE}\`travis_run_*\`${ANSI_RESET} functions (e.g., ${ANSI_BLUE}\`travis_run_before_install\`${ANSI_RESET}).

  For more information, consult https://docs.travis-ci.com/user/running-build-in-debug-mode/, or email support@travis-ci.com.

  "
  echo -en "${TMATE_MSG}" >"${TRAVIS_HOME}/.travis/debug_help"
  sync
  $TMATE new-session -d "cat ${TRAVIS_HOME}/.travis/debug_help; /bin/bash -l"
  $TMATE wait tmate-ready

  echo -e "${ANSI_YELLOW}Use the following SSH command to access the interactive debugging environment:${ANSI_RESET}"
  $TMATE display -p "$(echo -e "${ANSI_GREEN}#{tmate_ssh}${ANSI_RESET}")"

  if [[ "$QUIET" == "1" ]]; then
    echo -e "This build is running in quiet mode. No session output will be displayed.${ANSI_RESET}"
    echo -n .
    local counter=0
    while sleep 1 && $TMATE has-session &>/dev/null; do
      (((++counter % 60) == 0)) && echo -n .
    done
    echo
  else
    echo -e "Output from the interactive session will be shown below:${ANSI_RESET}"
    mkfifo /tmp/travis_debug.pipe
    $TMATE pipe-pane 'cat >> /tmp/travis_debug.pipe'
    cat /tmp/travis_debug.pipe
  fi
}

main "${@}"
