#!/bin/bash
source /etc/profile

RED="\033[31;1m"
GREEN="\033[32;1m"
RESET="\033[0m"

travis_assert() {
  local result=$?
  if [ $result -ne 0 ]; then
    echo -e "\n${RED}The command \"$TRAVIS_CMD\" failed and exited with $result during $TRAVIS_STAGE.${RESET}\n\nYour build has been stopped."
    travis_terminate 2
  fi
}

travis_result() {
  local result=$1
  export TRAVIS_TEST_RESULT=$(( ${TRAVIS_TEST_RESULT:-0} | $(($result != 0)) ))

  if [ $result -eq 0 ]; then
    echo -e "\n${GREEN}The command \"$TRAVIS_CMD\" exited with $result."
  else
    echo -e "\n${RED}The command \"$TRAVIS_CMD\" exited with $result."
  fi
}

travis_terminate() {
  pkill -9 -P $$ &> /dev/null || true
  exit $1
}

travis_wait() {
  local timeout=$1

  if [[ $timeout =~ ^[0-9]+$ ]]; then
    # looks like an integer, so we assume it's a timeout
    shift
  else
    # default value
    timeout=20
  fi

  local cmd="$@"
  local log_file=travis_wait_$$.log

  $cmd &>$log_file &
  local cmd_pid=$!

  travis_jigger $! $timeout $cmd &
  local jigger_pid=$!
  local result

  {
    wait $cmd_pid 2>/dev/null
    result=$?
    ps -p$jigger_pid &>/dev/null && kill $jigger_pid
  } || return 1

  if [ $result -eq 0 ]; then
    echo -e "\n${GREEN}The command \"$TRAVIS_CMD\" exited with $result.${RESET}"
  else
    echo -e "\n${RED}The command \"$TRAVIS_CMD\" exited with $result.${RESET}"
  fi

  echo -e "\n${GREEN}Log:${RESET}\n"
  cat $log_file

  return $result
}

travis_jigger() {
  # helper method for travis_wait()
  local cmd_pid=$1
  shift
  local timeout=$1 # in minutes
  shift
  local count=0


  # clear the line
  echo -e "\n"

  while [ $count -lt $timeout ]; do
    count=$(($count + 1))
    echo -ne "Still running ($count of $timeout): $@\r"
    sleep 60
  done

  echo -e "\n${RED}Timeout (${timeout} minutes) reached. Terminating \"$@\"${RESET}\n"
  kill -9 $cmd_pid
}

travis_retry() {
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n${RED}The command \"$@\" failed. Retrying, $count of 3.${RESET}\n" >&2
    }
    "$@"
    result=$?
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -eq 3 ] && {
    echo "\n${RED}The command \"$@\" failed 3 times.${RESET}\n" >&2
  }

  return $result
}

decrypt() {
  echo $1 | base64 -d | openssl rsautl -decrypt -inkey ~/.ssh/id_rsa.repo
}

mkdir -p <%= BUILD_DIR %>
cd       <%= BUILD_DIR %>

trap 'TRAVIS_CMD=$TRAVIS_NEXT_CMD; TRAVIS_NEXT_CMD=${BASH_COMMAND#travis_retry }' DEBUG
