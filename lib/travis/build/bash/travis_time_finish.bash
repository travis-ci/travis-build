travis_time_finish() {
  local result="${?}"
  local travis_timer_end_time
  travis_timer_end_time="$(travis_nanoseconds)"
  local duration
  local var_name
  local time_start
  local timer_id
  if [[ $# -gt 0 ]]; then
    var_name="TRAVIS_TIMER_ID_$1"
    time_start="TRAVIS_TIMER_START_TIME_$1"
    duration="$((travis_timer_end_time - ${!time_start}))"
    echo -en "travis_time:end:${!var_name}:start=${!time_start},finish=${travis_timer_end_time},duration=${duration}\\r${ANSI_CLEAR}"
    return ${result}
  fi

  duration="$((travis_timer_end_time - TRAVIS_TIMER_START_TIME))"
  echo -en "travis_time:end:${TRAVIS_TIMER_ID}:start=${TRAVIS_TIMER_START_TIME},finish=${travis_timer_end_time},duration=${duration}\\r${ANSI_CLEAR}"
  return "${result}"
}
