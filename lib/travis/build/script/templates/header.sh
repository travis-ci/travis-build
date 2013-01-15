#!/bin/bash
source /etc/profile

travis_start() {
  echo "[travis:$1:start]" <%= ">> #{logs[:state]}" if logs[:state] %>
}

travis_finish() {
  echo "[travis:$1:finish:result=$2]" <%= ">> #{logs[:state]}" if logs[:state] %>
  sleep 1
}

travis_assert() {
  if [ $? != 0 ]; then
    echo "Command did not exit with 0. Exiting." <%= ">> #{logs[:log]}" if logs[:log] %>
    travis_terminate 2
  fi
}

travis_terminate() {
  travis_finish build $1
  pkill -9 -P $$ > /dev/null 2>&1
  exit $1
}

decrypt() {
  echo $1 | base64 -d | openssl rsautl -decrypt -inkey ~/.ssh/id_rsa.repo
}

rm -rf   <%= BUILD_DIR %>
mkdir -p <%= BUILD_DIR %>
cd       <%= BUILD_DIR %>

trap 'travis_finish build 1' TERM

travis_start build
