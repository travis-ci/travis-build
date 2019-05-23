travis_stop_sauce_connect() {
  if [[ "${TRAVIS_SAUCE_CONNECT_PID}" == unset ]]; then
    echo 'No running Sauce Connect tunnel found'
    return 1
  fi

  kill "${TRAVIS_SAUCE_CONNECT_PID}"

  for i in 0 1 2 3 4 5 6 7 8 9; do
    if kill -0 "${TRAVIS_SAUCE_CONNECT_PID}" &>/dev/null; then
      echo "Waiting for graceful Sauce Connect shutdown ($((i + 1))/10)"
      sleep 1
    else
      echo 'Sauce Connect shutdown complete'
      return 0
    fi
  done

  if kill -0 "${TRAVIS_SAUCE_CONNECT_PID}" &>/dev/null; then
    echo 'Forcefully terminating Sauce Connect'
    kill -9 "${TRAVIS_SAUCE_CONNECT_PID}" &>/dev/null || true
  fi
}
