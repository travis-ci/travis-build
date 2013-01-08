echo
echo "Done. Build script exited with $TRAVIS_TEST_RESULT"

travis_terminate $TRAVIS_TEST_RESULT
