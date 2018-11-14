travis_time_start() {
  TRAVIS_TIMER_ID="$(printf %08x $((RANDOM * RANDOM)))"
  TRAVIS_TIMER_START_TIME="$(travis_nanoseconds)"
  export TRAVIS_TIMER_ID TRAVIS_TIMER_START_TIME
  echo -en "travis_time:start:$TRAVIS_TIMER_ID\\r${ANSI_CLEAR}"
}
