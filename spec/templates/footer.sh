echo
echo "Done. Build script exited with $TRAVIS_TEST_RESULT" <%= ">> #{logs[:build]}" if logs[:build] %>

travis_terminate $TRAVIS_TEST_RESULT

echo '-- env --'
env
