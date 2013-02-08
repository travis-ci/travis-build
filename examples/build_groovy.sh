#!/bin/bash
source /etc/profile

travis_start() {
  TRAVIS_STAGE=$1
  echo "[travis:$1:start]" 
}

travis_finish() {
  echo "[travis:$1:finish:result=$2]" 
  sleep 1
}

travis_assert() {
  local result=$?
  if [ $result -ne 0 ]; then
    echo -e "\nThe command \"$TRAVIS_CMD\" failed and exited with $result during $TRAVIS_STAGE.\n\nYour build has been stopped." 
    travis_terminate 2
  fi
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
trap 'TRAVIS_CMD=$TRAVIS_NEXT_CMD; TRAVIS_NEXT_CMD=$BASH_COMMAND' DEBUG

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
export TRAVIS_REPO_SLUG=travis-ci/travis-ci
echo \$\ export\ FOO\=foo
export FOO=foo
echo \$\ export\ BAR\=\[secure\]
export BAR=bar
travis_finish export $?

travis_start checkout
export GIT_ASKPASS=echo
echo \$\ git\ clone\ --depth\=100\ --quiet\ --branch\=master\ git://github.com/travis-ci/travis-ci.git\ travis-ci/travis-ci
git clone --depth=100 --quiet --branch=master git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci
travis_assert
echo \$\ cd\ travis-ci/travis-ci
cd travis-ci/travis-ci
echo \$\ git\ checkout\ -qf\ 313f61b
git checkout -qf 313f61b
travis_assert
if [[ -f .gitmodules ]]; then
  echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
  echo \$\ git\ submodule\ init
  git submodule init
  echo \$\ git\ submodule\ update
  git submodule update
  travis_assert
fi
rm -f ~/.ssh/source_rsa
travis_finish checkout $?

travis_start setup
travis_finish setup $?

travis_start announce
echo \$\ java\ -version
java -version
echo \$\ javac\ -version
javac -version
travis_finish announce $?

travis_start before_install
echo \$\ ./before_install_1.sh
./before_install_1.sh
travis_assert
echo \$\ ./before_install_2.sh
./before_install_2.sh
travis_assert
travis_finish before_install $?

travis_start install
if [[ -f build.gradle ]]; then
  echo \$\ gradle\ assemble
  gradle assemble
  travis_assert
elif [[ -f pom.xml ]]; then
  echo \$\ mvn\ install\ --quiet\ -DskipTests\=true
  mvn install --quiet -DskipTests=true
  travis_assert
fi
travis_finish install $?

travis_start before_script
echo \$\ ./before_script_1.sh
./before_script_1.sh
travis_assert
echo \$\ ./before_script_2.sh
./before_script_2.sh
travis_assert
travis_finish before_script $?

travis_start script
if [[ -f build.gradle ]]; then
  echo \$\ gradle\ check
  gradle check
elif [[ -f pom.xml ]]; then
  echo \$\ mvn\ test
  mvn test
else
  echo \$\ ant\ test
  ant test
fi
export TRAVIS_TEST_RESULT=$((${TRAVIS_TEST_RESULT:-0} | $(($? != 0))))
travis_finish script $TRAVIS_TEST_RESULT

if [[ $TRAVIS_TEST_RESULT = 0 ]]; then
  travis_start after_success
  echo \$\ ./after_success_1.sh
  ./after_success_1.sh
  echo \$\ ./after_success_2.sh
  ./after_success_2.sh
  travis_finish after_success $?
fi
if [[ $TRAVIS_TEST_RESULT != 0 ]]; then
  travis_start after_failure
  echo \$\ ./after_failure_1.sh
  ./after_failure_1.sh
  echo \$\ ./after_failure_2.sh
  ./after_failure_2.sh
  travis_finish after_failure $?
fi

travis_start after_script
echo \$\ ./after_script_1.sh
./after_script_1.sh
echo \$\ ./after_script_2.sh
./after_script_2.sh
travis_finish after_script $?

echo
echo "Done. Build script exited with $TRAVIS_TEST_RESULT" 

travis_terminate $TRAVIS_TEST_RESULT
