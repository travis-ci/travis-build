echo
echo "Done. Build script exited with $TRAVIS_TEST_RESULT" <%= ">> #{LOGS[:log]}" if LOGS[:log] %>

travis_terminate $TRAVIS_TEST_RESULT
