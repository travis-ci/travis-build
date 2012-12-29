travis_start() {
  echo "`date +%s.%N` [$1] start" >> ~/state.log
}

travis_end() {
  echo "`date +%s.%N` [$1] end, result: $?" >> ~/state.log
}

travis_assert() {
  if [ $? != 0 ]; then
    echo "Command did not exit with 0. Exiting." >> ~/build.log
    echo "`date +%s.%N` Command did not exit with 0. Exiting." >> ~/state.log
    kill $$
  fi
}

travis_timeout() {
  local pid=$!
  local start=$(date +%s)
  while ps aux | awk '{print $2 }' | grep -q $pid 2> /dev/null; do
    if [ $(expr $(date +%s) - $start) -gt $1 ]; then
      echo "Command timed out after $1 seconds. Exiting." >> ~/build.log
      kill -9 $pid
      kill $$
    fi
  done
  wait $pid
}

mkdir -p ~/builds
cd ~/builds

touch ~/build.log; > ~/build.log
touch ~/state.log; > ~/state.log
echo \#\!/usr/bin/env\ ruby'
'require\ \'net/http\''
'require\ \'uri\''
''
'source,\ target,\ interval\ \=\ ARGV'
'target\ \=\ URI.parse\(target\)'
'interval\ \|\|\=\ 1'
''
'file\ \=\ File.open\(source,\ \'r\+\'\)'
'buff\ \=\ \'\''
''
'post\ \=\ -\>\(data\)\ do'
'\ \ Net::HTTP.post_form\(target,\ log:\ data\)'
'end'
''
'at_exit\ do'
'\ \ file.close'
'\ \ post.call\(buff\)'
'end'
''
'loop\ do'
'\ \ buff\ \<\<\ file.getc\ until\ file.eof\?'
'\ \ post.call\(buff\)\ unless\ buff.empty\?'
'\ \ buff.clear'
'\ \ sleep\ interval'
'end'
''
' > ~/travis_stream
chmod +x ~/travis_stream

~/travis_stream ~/build.log http://requestb.in/18ygqfo1 &
~/travis_stream ~/state.log http://requestb.in/12g6u3e1 &
travis_start 'export'
TRAVIS_PULL_REQUEST=false
TRAVIS_SECURE_ENV_VARS=false
TRAVIS_BUILD_ID=1
TRAVIS_BUILD_NUMBER=
TRAVIS_JOB_ID=
TRAVIS_JOB_NUMBER=
TRAVIS_BRANCH=
TRAVIS_COMMIT_RANGE=
TRAVIS_COMMIT=a214c21
TRAVIS_RUBY_VERSION=default
travis_end 'export'

travis_start 'checkout'
GIT_ASKPASS=echo
rm -rf travis-ci/travis-support
echo \$\ git\ clone\ --depth\=100\ --quiet\ http://github.com/travis-ci/travis-support.git\ travis-ci/travis-support >> ~/build.log 2>&1
((git clone --depth=100 --quiet http://github.com/travis-ci/travis-support.git travis-ci/travis-support) >> ~/build.log 2>&1) &
travis_timeout 300
travis_assert
rm -f ~/.ssh/source_rsa
echo \$\ cd\ travis-ci/travis-support >> ~/build.log 2>&1
cd travis-ci/travis-support
echo \$\ git\ checkout\ -qf\ a214c21 >> ~/build.log 2>&1
(git checkout -qf a214c21) >> ~/build.log 2>&1
travis_assert
if [[ -s .gitmodules ]]; then
  (echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config) >> ~/build.log 2>&1
  echo \$\ git\ submodule\ init >> ~/build.log 2>&1
  (git submodule init) >> ~/build.log 2>&1
  echo \$\ git\ submodule\ update >> ~/build.log 2>&1
  ((git submodule update) >> ~/build.log 2>&1) &
  travis_timeout 300
  travis_assert
fi
travis_end 'checkout'

travis_start 'setup'
echo \$\ rvm\ use\ default >> ~/build.log 2>&1
(rvm use default) >> ~/build.log 2>&1
travis_assert
if [[ -f Gemfile ]]; then
  BUNDLE_GEMFILE=$pwd/Gemfile
fi
travis_end 'setup'

travis_start 'announce'
echo \$\ java\ -version >> ~/build.log 2>&1
(java -version) >> ~/build.log 2>&1
echo \$\ javac\ -version >> ~/build.log 2>&1
(javac -version) >> ~/build.log 2>&1
echo \$\ ruby\ --version >> ~/build.log 2>&1
(ruby --version) >> ~/build.log 2>&1
echo \$\ gem\ --version >> ~/build.log 2>&1
(gem --version) >> ~/build.log 2>&1
travis_end 'announce'

travis_start 'install'
if [[ -f Gemfile ]]; then
  echo \$\ bundle\ install\  >> ~/build.log 2>&1
  ((bundle install ) >> ~/build.log 2>&1) &
  travis_timeout 600
  travis_assert
fi
travis_end 'install'

travis_start 'script'
if [[ -f Gemfile ]]; then
  echo \$\ bundle\ exec\ rake >> ~/build.log 2>&1
  ((bundle exec rake) >> ~/build.log 2>&1) &
  travis_timeout 1500
else
  echo \$\ rake >> ~/build.log 2>&1
  ((rake) >> ~/build.log 2>&1) &
  travis_timeout 1500
fi
TRAVIS_TEST_RESULT=$?
travis_end 'script'



echo "\n\nDone. Build script exited with $TRAVIS_TEST_RESULT" >> ~/build.log
exit $TRAVIS_TEST_RESULT
