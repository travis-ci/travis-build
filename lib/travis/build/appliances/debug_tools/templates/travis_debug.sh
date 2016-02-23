#!/bin/bash
set -e
ANSI_RED="\033[31;1m"
ANSI_GREEN="\033[32;1m"
ANSI_YELLOW="\033[33;1m"
ANSI_RESET="\033[0m"
ANSI_CLEAR="\033[0K"

TMATE="tmate -S /tmp/tmate.sock"

$TMATE new-session -d '/bin/bash'
$TMATE wait tmate-ready

echo -e "${ANSI_YELLOW}Use any of the following connections to access the debugging environment:${ANSI_RESET}"
$TMATE display -p `echo -e "${ANSI_GREEN}#{tmate_ssh}${ANSI_RESET}"`
$TMATE display -p `echo -e "${ANSI_GREEN}#{tmate_web}${ANSI_RESET}"`

if [ "$1" == "private" ]; then
  # TODO detect ssh connection close instead of sleeping forever.
  while sleep 60; do echo .; done
else
  mkfifo /tmp/travis_debug.pipe
  $TMATE pipe-pane 'cat >> /tmp/travis_debug.pipe'
  cat /tmp/travis_debug.pipe
fi
