echo "\n\nDone. Build script exited with $TRAVIS_TEST_RESULT" >> <%= LOGS[:log] %>

travis_terminate $TRAVIS_TEST_RESULT
