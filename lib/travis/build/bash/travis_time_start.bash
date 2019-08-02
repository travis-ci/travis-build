travis_time_start() {
  local timer_id="$(printf %08x $((RANDOM * RANDOM)))"
  local timer_name
  if [[ $# -gt 0 ]]; then
    eval "TRAVIS_TIMER_ID_$1=${timer_id}"
    export TRAVIS_TIMER_ID_$1
    eval "TRAVIS_TIMER_START_TIME_$1=$(travis_nanoseconds)"
    export TRAVIS_TIMER_START_TIME_$1
    timer_name="TRAVIS_TIMER_ID_$1"
    echo -en "travis_time:start:${!timer_name}\\r${ANSI_CLEAR}"
    return
  fi

  TRAVIS_TIMER_ID=${timer_id}
  TRAVIS_TIMER_START_TIME="$(travis_nanoseconds)"
  export TRAVIS_TIMER_ID TRAVIS_TIMER_START_TIME
  echo -en "travis_time:start:$TRAVIS_TIMER_ID\\r${ANSI_CLEAR}"
}
