#!/bin/bash
source /etc/profile

travis_start() {
  TRAVIS_STAGE=$1
  echo "[travis:$1:start]" <%= ">> #{logs[:state]}" if logs[:state] %>
}

travis_finish() {
  echo "[travis:$1:finish:result=$2]" <%= ">> #{logs[:state]}" if logs[:state] %>
  sleep 1
}

travis_assert() {
  local result=$?
  if [ $result -ne 0 ]; then
    echo -e "\nThe command \"$TRAVIS_CMD\" failed and exited with $result during $TRAVIS_STAGE.\n\nYour build has been stopped." <%= ">> #{logs[:log]}" if logs[:log] %>
    travis_terminate 2
  fi
}

travis_result() {
  local result=$1
  export TRAVIS_TEST_RESULT=$(( ${TRAVIS_TEST_RESULT:-0} | $(($result != 0)) ))
  echo -e "\nThe command \"$TRAVIS_CMD\" exited with $result."<%= " >> #{logs[:log]}" if logs[:log] %>
}

travis_terminate() {
  travis_finish build $1
  pkill -9 -P $$ > /dev/null 2>&1
  exit $1
}

travis_retry() {
  local result=0
  local count=3
  while [ $count -gt 0 ]; do
    "$@"
    result=$?
    [[ "$result" == "0" ]] && break
    count=$(($count - 1))
    echo -e "\n\033[33;1mThe command \"$@\" failed. Retrying, $((3 - $count)) of 3.\033[0m\n" >&2
    sleep 1
  done

  [ $count -eq 0 ] && {
    echo "\n\033[33;1mThe command \"$@\" failed 3 times.\033[0m\n" >&2
  }

  return $result
}

decrypt() {
  echo $1 | base64 -d | openssl rsautl -decrypt -inkey ~/.ssh/id_rsa.repo
}

mkdir -p <%= BUILD_DIR %>
cd       <%= BUILD_DIR %>

trap 'travis_finish build 1' TERM
trap 'TRAVIS_CMD=$TRAVIS_NEXT_CMD; TRAVIS_NEXT_CMD=$BASH_COMMAND' DEBUG

travis_start build
