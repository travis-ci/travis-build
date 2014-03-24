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
    echo -e "\n\033[33;1mThe command \"$TRAVIS_CMD\" failed and exited with $result during $TRAVIS_STAGE.\e[0m\n\nYour build has been stopped." <%= ">> #{logs[:log]}" if logs[:log] %>
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
  pkill -9 -P $$ > /dev/null 2>&1 || true
  exit $1
}

travis_wait() {
  local cmd="$@"
  local log_file=travis_wait_$$.log

  $cmd 2>&1 >$log_file &
  local cmd_pid=$!

  travis_jigger $! $cmd &
  local jigger_pid=$!
  local result

  {
    wait $cmd_pid 2>/dev/null
    result=$?
    ps -p$jigger_pid 2>&1>/dev/null && kill $jigger_pid
  } || return 1

  echo -e "\nThe command \"$cmd\" exited with $result."
  echo -e "\n\033[32;1mLog:\033[0m\n"
  cat $log_file

  return $result
}

travis_jigger() {
  # helper method for travis_wait()
  local timeout=20 # in minutes
  local count=0

  local cmd_pid=$1
  shift

  # clear the line
  echo -e "\n"

  while [ $count -lt $timeout ]; do
    count=$(($count + 1))
    echo -ne "Still running ($count of $timeout): $@\r"
    sleep 60
  done

  echo -e "\n\033[31;1mTimeout reached. Terminating $@\033[0m\n"
  kill -9 $cmd_pid
}

travis_retry() {
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n\033[33;1mThe command \"$@\" failed. Retrying, $count of 3.\033[0m\n" >&2
    }
    "$@"
    result=$?
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -eq 3 ] && {
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
trap 'TRAVIS_CMD=$TRAVIS_NEXT_CMD; TRAVIS_NEXT_CMD=${BASH_COMMAND#travis_retry }' DEBUG

travis_start build
