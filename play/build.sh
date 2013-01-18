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

travis_start build
travis_start export
export TRAVIS_PULL_REQUEST=false
export TRAVIS_SECURE_ENV_VARS=false
export TRAVIS_BUILD_ID=1
export TRAVIS_BUILD_NUMBER=1
export TRAVIS_JOB_ID=1
export TRAVIS_JOB_NUMBER=1.1
export TRAVIS_BRANCH=master
export TRAVIS_COMMIT=a214c21
export TRAVIS_COMMIT_RANGE=abcdefg..a214c21
export TRAVIS_REPO_SLUG=
echo \$\ export\ NUODB_ROOT\=/opt/nuodb
export NUODB_ROOT=/opt/nuodb
export TRAVIS_NODE_VERSION=[0.6]
travis_finish export $?

travis_start checkout
export GIT_ASKPASS=echo
echo \$\ git\ clone\ --depth\=100\ --quiet\ --branch\=master\ http://github.com/travis-ci/travis-support.git\ travis-ci/travis-support
git clone --depth=100 --quiet --branch=master http://github.com/travis-ci/travis-support.git travis-ci/travis-support
travis_assert
echo \$\ cd\ travis-ci/travis-support
cd travis-ci/travis-support
echo \$\ git\ checkout\ -qf\ a214c21
git checkout -qf a214c21
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
echo \$\ nvm\ use\ \[0.6\]
nvm use [0.6]
travis_assert
travis_finish setup $?

travis_start announce
echo \$\ node\ --version
node --version
echo \$\ npm\ --version
npm --version
travis_finish announce $?

travis_start install
if [[ -f package.json ]]; then
  echo \$\ npm\ install\ 
  npm install 
  travis_assert
fi
travis_finish install $?

travis_start before_script
echo \$\ wget\ http://www.nuodb.com/latest/nuodb-1.0-GA.linux.x86_64.deb\ --output-document\=/var/tmp/nuodb.deb
wget http://www.nuodb.com/latest/nuodb-1.0-GA.linux.x86_64.deb --output-document=/var/tmp/nuodb.deb
travis_assert
echo \$\ sudo\ dpkg\ -i\ /var/tmp/nuodb.deb
sudo dpkg -i /var/tmp/nuodb.deb
travis_assert
travis_finish before_script $?

travis_start script
echo \$\ which\ node
which node
export TRAVIS_TEST_RESULT=$?
travis_finish script $TRAVIS_TEST_RESULT



travis_start after_script
echo \$\ sudo\ dpkg\ -r\ nuodb
sudo dpkg -r nuodb
travis_finish after_script $?

echo
echo "Done. Build script exited with $TRAVIS_TEST_RESULT" 

travis_terminate $TRAVIS_TEST_RESULT
