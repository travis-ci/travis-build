travis_footer() {
  : "${TRAVIS_TEST_RESULT:=86}"
  echo -e "\\nDone. Your build exited with ${TRAVIS_TEST_RESULT}."
  travis_terminate "${TRAVIS_TEST_RESULT}"
}
