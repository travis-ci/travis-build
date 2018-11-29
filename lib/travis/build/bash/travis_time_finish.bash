travis_time_finish() {
  local result="${?}"
  local travis_timer_end_time
  travis_timer_end_time="$(travis_nanoseconds)"
  local duration
  duration="$((travis_timer_end_time - TRAVIS_TIMER_START_TIME))"
  echo -en "travis_time:end:${TRAVIS_TIMER_ID}:start=${TRAVIS_TIMER_START_TIME},finish=${travis_timer_end_time},duration=${duration}\\r${ANSI_CLEAR}"
  return "${result}"
}
