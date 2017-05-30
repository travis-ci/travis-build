#!/bin/bash
set -e
ANSI_RED="\033[31;1m"
ANSI_GREEN="\033[32;1m"
ANSI_YELLOW="\033[33;1m"
ANSI_RESET="\033[0m"
ANSI_CLEAR="\033[0K"

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

$TMATE new-session -d '/bin/bash -l'
$TMATE wait tmate-ready

echo -e "${ANSI_YELLOW}Use the following SSH command to access the interactive debugging environment:${ANSI_RESET}"
$TMATE display -p `echo -e "${ANSI_GREEN}#{tmate_ssh}${ANSI_RESET}"`

if [[ "$QUIET" == "1" ]]; then
  echo -e "This build is running in quiet mode. No session output will be displayed.${ANSI_RESET}"
  echo -e "This debug build will stay alive for 30 minutes.${ANSI_RESET}"
  echo -n .
  while $TMATE has-session &> /dev/null; do
    sleep 1
    (( ++i % 60 == 0 )) && echo -n .
  done
  echo
else
  echo -e "Output from the interactive session will be shown below:${ANSI_RESET}"
  mkfifo /tmp/travis_debug.pipe
  $TMATE pipe-pane 'cat >> /tmp/travis_debug.pipe'
  cat /tmp/travis_debug.pipe
fi
