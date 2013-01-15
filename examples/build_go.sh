#!/bin/bash
source /etc/profile

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

decrypt() {
  echo $1 | base64 -d | openssl rsautl -decrypt -inkey ~/.ssh/id_rsa.repo
}

rm -rf   ~/build
mkdir -p ~/build
cd       ~/build

trap 'travis_finish build 1' TERM

travis_start build
travis_start export
export TRAVIS_PULL_REQUEST=false
export TRAVIS_SECURE_ENV_VARS=true
export TRAVIS_BUILD_ID=1
export TRAVIS_BUILD_NUMBER=1
export TRAVIS_JOB_ID=1
export TRAVIS_JOB_NUMBER=1.1
export TRAVIS_BRANCH=master
export TRAVIS_COMMIT=313f61b
export TRAVIS_COMMIT_RANGE=313f61b..313f61a
echo \$\ export\ FOO\=foo
export FOO=foo
echo \$\ export\ BAR\=\[secure\]
export BAR=bar
echo \$\ export\ GOPATH\=\~/gopath
export GOPATH=~/gopath
travis_finish export $?

travis_start checkout
export GIT_ASKPASS=echo
echo \$\ git\ clone\ --depth\=100\ --quiet\ --branch\=master\ git://github.com/travis-ci/travis-ci.git\ travis-ci/travis-ci
((git clone --depth=100 --quiet --branch=master git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci) >> ~/build.log 2>&1) &
travis_timeout 300
travis_assert
echo \$\ cd\ travis-ci/travis-ci
(cd travis-ci/travis-ci) >> ~/build.log 2>&1
echo \$\ git\ checkout\ -qf\ 313f61b
(git checkout -qf 313f61b) >> ~/build.log 2>&1
travis_assert
if [[ -f .gitmodules ]]; then
  (echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config) >> ~/build.log 2>&1
  echo \$\ git\ submodule\ init
  (git submodule init) >> ~/build.log 2>&1
  echo \$\ git\ submodule\ update
  ((git submodule update) >> ~/build.log 2>&1) &
  travis_timeout 300
  travis_assert
fi
rm -f ~/.ssh/source_rsa
travis_finish checkout $?

travis_start setup
echo \$\ mkdir\ -p\ \$GOPATH/src
(mkdir -p $GOPATH/src) >> ~/build.log 2>&1
travis_assert
travis_finish setup $?

travis_start announce
travis_finish announce $?

travis_start before_install
echo \$\ ./before_install_1.sh
((./before_install_1.sh) >> ~/build.log 2>&1) &
travis_timeout 300
travis_assert
echo \$\ ./before_install_2.sh
((./before_install_2.sh) >> ~/build.log 2>&1) &
travis_timeout 300
travis_assert
travis_finish before_install $?

travis_start install
if [[ -f Makefile ]]; then
  echo \$\ /usr/bin/true
  ((/usr/bin/true) >> ~/build.log 2>&1) &
  travis_timeout 600
  travis_assert
else
  echo \$\ go\ get\ -d\ -v\ ./...\ \&\&\ go\ build\ -v\ ./...
  ((go get -d -v ./... && go build -v ./...) >> ~/build.log 2>&1) &
  travis_timeout 600
  travis_assert
fi
travis_finish install $?

travis_start before_script
echo \$\ ./before_script_1.sh
((./before_script_1.sh) >> ~/build.log 2>&1) &
travis_timeout 600
travis_assert
echo \$\ ./before_script_2.sh
((./before_script_2.sh) >> ~/build.log 2>&1) &
travis_timeout 600
travis_assert
travis_finish before_script $?

travis_start script
if [[ -f Makefile ]]; then
  echo \$\ make
  ((make) >> ~/build.log 2>&1) &
  travis_timeout 1500
else
  echo \$\ go\ test\ -v
  ((go test -v) >> ~/build.log 2>&1) &
  travis_timeout 1500
fi
export TRAVIS_TEST_RESULT=$?
travis_finish script $TRAVIS_TEST_RESULT

if [[ $TRAVIS_TEST_RESULT = 0 ]]; then
  travis_start after_success
  echo \$\ ./after_success_1.sh
  ((./after_success_1.sh) >> ~/build.log 2>&1) &
  travis_timeout 300
  echo \$\ ./after_success_2.sh
  ((./after_success_2.sh) >> ~/build.log 2>&1) &
  travis_timeout 300
  travis_finish after_success $?
fi
if [[ $TRAVIS_TEST_RESULT != 0 ]]; then
  travis_start after_failure
  echo \$\ ./after_failure_1.sh
  ((./after_failure_1.sh) >> ~/build.log 2>&1) &
  travis_timeout 300
  echo \$\ ./after_failure_2.sh
  ((./after_failure_2.sh) >> ~/build.log 2>&1) &
  travis_timeout 300
  travis_finish after_failure $?
fi

travis_start after_script
echo \$\ ./after_script_1.sh
((./after_script_1.sh) >> ~/build.log 2>&1) &
travis_timeout 300
echo \$\ ./after_script_2.sh
((./after_script_2.sh) >> ~/build.log 2>&1) &
travis_timeout 300
travis_finish after_script $?

echo
echo "Done. Build script exited with $TRAVIS_TEST_RESULT" >> ~/build.log

travis_terminate $TRAVIS_TEST_RESULT
