travis_nanoseconds() {
  local cmd='date'
  local format='+%s%N'

  if hash gdate >/dev/null 2>&1; then
    cmd='gdate'
  elif [[ "${TRAVIS_OS_NAME}" == osx ]]; then
    format='+%s000000000'
  fi

  "${cmd}" -u "${format}"
}
