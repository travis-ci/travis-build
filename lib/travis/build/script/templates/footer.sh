echo "\n\nDone. Build script exited with $TRAVIS_TEST_RESULT" >> <%= LOGS[:logs] %>
exit $TRAVIS_TEST_RESULT
