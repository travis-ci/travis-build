#!/bin/bash
set -e
ANSI_RED="\033[31;1m"
ANSI_GREEN="\033[32;1m"
ANSI_YELLOW="\033[33;1m"
ANSI_BLUE="\033[34;1m"
ANSI_RESET="\033[0m"
ANSI_CLEAR="\033[0K"

TIMEOUT=30 # minutes

TMATE="tmate -S /tmp/tmate.sock"

function warn() {
  echo -e "${ANSI_YELLOW}travis_debug: $1${ANSI_RESET}" 1>&2
}

while [[ $# > 0 ]]; do
  case "$1" in
    -q|--quiet) QUIET=1; shift ;;
    *) warn "Unknown argument: $1"; shift ;;
  esac
done

TMATE_MSG="
Run individual commands; or execute configured build phases
with ${ANSI_BLUE}\`travis_run_*\`${ANSI_RESET} functions (e.g., ${ANSI_BLUE}\`travis_run_before_install\`${ANSI_RESET}).

For more information, consult https://docs.travis-ci.com/user/running-build-in-debug-mode/, or email support@travis-ci.com.

"

echo -en "${TMATE_MSG}" > $HOME/.travis/debug_help
sleep 2 # this sleep is necessary so that `echo`'s buffer can be flushed to disk
        # before starting the tmate session
$TMATE new-session -d "cat $HOME/.travis/debug_help; /bin/bash -l"
$TMATE wait tmate-ready

echo -e "${ANSI_YELLOW}Use the following SSH command to access the interactive debugging environment:${ANSI_RESET}"
$TMATE display -p `echo -e "${ANSI_GREEN}#{tmate_ssh}${ANSI_RESET}"`

minute=0
second=0
if [[ "$QUIET" == "1" ]]; then
  echo -e "This build is running in quiet mode. No session output will be displayed.${ANSI_RESET}"
  echo -e "This debug build will stay alive for ${TIMEOUT} minutes.${ANSI_RESET}"
  echo -n .
  while (( $minute < $TIMEOUT )) && $TMATE has-session &> /dev/null; do
    sleep 1
    (( ++second % 60 == 0 )) && (( minute++ )) && echo -n .
  done
  echo
else
  echo -e "Output from the interactive session will be shown below:${ANSI_RESET}"
  mkfifo /tmp/travis_debug.pipe
  $TMATE pipe-pane 'cat >> /tmp/travis_debug.pipe'
  cat /tmp/travis_debug.pipe
fi
