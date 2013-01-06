travis_start() {
  echo "`date +%s.%N` [$1:start]" >> <%= LOGS[:state] %>
}

travis_finish() {
  echo "`date +%s.%N` [$1:finish] result: $?" >> <%= LOGS[:state] %>
}

travis_assert() {
  if [ $? != 0 ]; then
    echo "Command did not exit with 0. Exiting." >> <%= LOGS[:logs] %>
    exit 1
  fi
}

travis_timeout() {
  local pid=$!
  local start=$(date +%s)
  while ps aux | awk '{print $2 }' | grep -q $pid 2> /dev/null; do
    if [ $(expr $(date +%s) - $start) -gt $1 ]; then
      echo "Command timed out after $1 seconds. Exiting." >> <%= LOGS[:logs] %>
      kill -9 $pid
      exit 1
    fi
  done
  wait $pid
}

rm -rf   <%= BUILD_DIR %>
mkdir -p <%= BUILD_DIR %>
cd       <%= BUILD_DIR %>

<%= LOGS.map { |name, path| "touch #{path}; > #{path}" }.join("\n") %>

trap 'travis_finish build' EXIT
trap 'travis_finish build' TERM

travis_start build
