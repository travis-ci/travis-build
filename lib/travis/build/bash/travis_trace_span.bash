travis_trace_span() {
  local result="${?}"
  local template="${1}"
  local timestamp
  timestamp="$(travis_nanoseconds)"
  template="${template/__TRAVIS_TIMESTAMP__/${timestamp}}"
  template="${template/__TRAVIS_STATUS__/${result}}"
  echo "${template}" >>/tmp/build.trace
  return "${result}"
}
