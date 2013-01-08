travis_start() {
  echo "[travis:$1:start]"
}

travis_finish() {
  echo "[travis:$1:finish:result=$2]"
  sleep 1
}

travis_assert() {
  if [ $? != 0 ]; then
    echo "Command did not exit with 0. Exiting."
    travis_terminate 1
  fi
}

travis_timeout() {
  local pid=$!
  local start=$(date +%s)
  while ps aux | awk '{print $2 }' | grep -q $pid 2> /dev/null; do
    if [ $(expr $(date +%s) - $start) -gt $1 ]; then
      echo "Command timed out after $1 seconds. Exiting."
      travis_terminate 1
    fi
  done
  wait $pid
}

travis_terminate() {
  travis_finish build $1
  pkill -9 -P $$ > /dev/null 2>&1
  exit $1
}

rm -rf   <%= BUILD_DIR %>
mkdir -p <%= BUILD_DIR %>
cd       <%= BUILD_DIR %>

trap 'travis_finish build 1' TERM

travis_start build
