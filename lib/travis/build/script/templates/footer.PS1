echo
echo "Done. Build script exited with $global:TRAVIS_TEST_RESULT" <%= ">> #{logs[:build]}" if logs[:build] %>

travis_terminate $global:TRAVIS_TEST_RESULT
