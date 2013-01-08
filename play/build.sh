travis_start() {
  echo "[travis:$1:start]" >> ~/state.log
}

travis_finish() {
  echo "[travis:$1:finish:result=$2]" >> ~/state.log
  sleep 1
}

travis_assert() {
  if [ $? != 0 ]; then
    echo "Command did not exit with 0. Exiting."
    travis_terminate 1
  fi
}

travis_timeout() {
  local pid=$!
  local start=$(date +%s)
  while ps aux | awk '{print $2 }' | grep -q $pid 2> /dev/null; do
    if [ $(expr $(date +%s) - $start) -gt $1 ]; then
      echo "Command timed out after $1 seconds. Exiting."
      travis_terminate 1
    fi
  done
  wait $pid
}

travis_terminate() {
  travis_finish build $1
  pkill -9 -P $$ > /dev/null 2>&1
  exit $1
}

rm -rf   ~/build
mkdir -p ~/build
cd       ~/build

trap 'travis_finish build 1' TERM

travis_start build
travis_start export
TRAVIS_PULL_REQUEST=false
TRAVIS_SECURE_ENV_VARS=false
TRAVIS_BUILD_ID=1804636
TRAVIS_BUILD_NUMBER=141
TRAVIS_JOB_ID=1804637
TRAVIS_JOB_NUMBER=141.1
TRAVIS_BRANCH=master
TRAVIS_COMMIT=1e76ebd1108dd918bd0d17c5f241a7984292b31f
TRAVIS_COMMIT_RANGE=ad079609a408...1e76ebd1108d
TRAVIS_RUBY_VERSION=1.9.3
travis_finish export $?

travis_start checkout
GIT_ASKPASS=echo
echo \$\ git\ clone\ --depth\=100\ --quiet\ git://github.com/travis-ci/travis-support.git\ .
(git clone --depth=100 --quiet git://github.com/travis-ci/travis-support.git .) &
travis_timeout 300
travis_assert
rm -f ~/.ssh/source_rsa
echo \$\ git\ checkout\ -qf\ 1e76ebd1108dd918bd0d17c5f241a7984292b31f
git checkout -qf 1e76ebd1108dd918bd0d17c5f241a7984292b31f
travis_assert
if [[ -s .gitmodules ]]; then
  echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
  echo \$\ git\ submodule\ init
  git submodule init
  echo \$\ git\ submodule\ update
  (git submodule update) &
  travis_timeout 300
  travis_assert
fi
travis_finish checkout $?

travis_start setup
echo \$\ rvm\ use\ 1.9.3
rvm use 1.9.3
travis_assert
if [[ -f Gemfile ]]; then
  BUNDLE_GEMFILE=$pwd/Gemfile
fi
travis_finish setup $?

travis_start announce
echo \$\ java\ -version
java -version
echo \$\ javac\ -version
javac -version
echo \$\ ruby\ --version
ruby --version
echo \$\ gem\ --version
gem --version
travis_finish announce $?

travis_start install
if [[ -f Gemfile ]]; then
  echo \$\ bundle\ install\
  (bundle install ) &
  travis_timeout 600
  travis_assert
fi
travis_finish install $?

travis_start script
if [[ -f Gemfile ]]; then
  echo \$\ bundle\ exec\ rake
  (bundle exec rake) &
  travis_timeout 1500
else
  echo \$\ rake
  (rake) &
  travis_timeout 1500
fi
TRAVIS_TEST_RESULT=$?
travis_finish script $TRAVIS_TEST_RESULT



echo
echo "Done. Build script exited with $TRAVIS_TEST_RESULT"

travis_terminate $TRAVIS_TEST_RESULT
