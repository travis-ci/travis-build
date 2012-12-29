echo "\n\nDone. Build script exited with $TRAVIS_TEST_RESULT" >> <%= LOGS[:build] %>
exit $TRAVIS_TEST_RESULT
