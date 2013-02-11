echo -e "\nDone. Your build exited with $TRAVIS_TEST_RESULT."<%= " >> #{logs[:build]}" if logs[:build] %>

travis_terminate $TRAVIS_TEST_RESULT
