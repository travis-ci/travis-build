    echo \#\!/usr/bin/env\ ruby'
''
'require\ \'net/http\''
'require\ \'uri\''
''
'source,\ target,\ interval\ \=\ ARGV'
'target\ \=\ URI.parse\(target\)'
'interval\ \|\|\=\ 0.5'
''
'file\ \=\ File.open\(source,\ \'r\+\'\)'
'buff\ \=\ \'\''
''
'post\ \=\ -\>\(data\)\ do'
'\ \ Net::HTTP.post_form\(target,\ data\)'
'end'
''
'at_exit\ do'
'\ \ file.close'
'\ \ post.call\(final:\ true,\ log:\ buff\)'
'end'
''
'loop\ do'
'\ \ buff\ \<\<\ file.getc\ until\ file.eof\?'
'\ \ post.call\(log:\ buff\)\ unless\ buff.empty\?'
'\ \ buff.clear'
'\ \ sleep\ interval'
'end'
''
' > ~/travis_report_log.rb
    ruby ~/travis_report_log.rb ~/build.log http://192.168.2.100:3000/jobs/1804637/log &



    echo \#\!/usr/bin/env\ ruby'
''
'require\ \'net/http\''
'require\ \'uri\''
'require\ \'json\''
''
'source,\ target\ \=\ ARGV'
'target\ \=\ URI.parse\(target\)'
''
'file\ \=\ File.open\(source,\ \'r\+\'\)'
'last_state,\ last_stage\ \=\ nil,\ nil'
''
'post\ \=\ -\>\(data\)\ do'
'\ \ p\ data'
'\ \ Net::HTTP.post_form\(target,\ data\)'
'end'
''
'on_start\ \=\ -\>\(line\)\ do'
'\ \ post.call\(event:\ :start,\ started_at:\ Time.now,\ worker:\ \`hostname\`\)'
'end'
''
'on_finish\ \=\ -\>\(line,\ result\)\ do'
'\ \ state\ \=\ last_state\ \=\=\ \'start\'\ \?\ :errored\ :\ \(result\ \=\=\ 0\ \?\ :passed\ :\ :failed\)'
'\ \ data\ \=\ \{\ event:\ :finish,\ state:\ state,\ finished_at:\ Time.now\ \}'
'\ \ data\[:error\]\ \=\ :\"\#\{last_stage\}_failed\"\ if\ state\ \=\=\ :errored'
'\ \ post.call\(data\)'
'end'
''
'report\ \=\ -\>\(line\)\ do'
'\ \ case\ line'
'\ \ when\ /\\\[build:start\\\]/'
'\ \ \ \ on_start.call\(line\)'
'\ \ when\ /\\\[build:finish\\\]\ result:\ \(\[\\d\]\+\)/'
'\ \ \ \ on_finish.call\(line,\ \$1.to_i\)'
'\ \ when\ /\\\[\(.\+\):\(.\+\)\\\]/'
'\ \ \ \ last_stage,\ last_state\ \=\ \$1,\ \$2'
'\ \ end'
'end'
''
'loop\ do'
'\ \ sleep\ 0.1\ while\ file.eof\?'
'\ \ report.call\(file.readline\)'
'end'
' > ~/travis_report_state.rb
    ruby ~/travis_report_state.rb ~/state.log http://192.168.2.100:3000/jobs/1804637/state &

travis_start() {
  echo "travis_start $1"
  echo "`date +%s.%N` [$1:start]" >> ~/state.log
}

travis_finish() {
  echo "travis_finish $1 ($?)"
  echo "`date +%s.%N` [$1:finish] result: $?" >> ~/state.log
  sleep 1
}

travis_assert() {
  if [ $? != 0 ]; then
    echo "Command did not exit with 0. Exiting." >> ~/build.log
    travis_terminate 1
  fi
}

travis_timeout() {
  local pid=$!
  local start=$(date +%s)
  while ps aux | awk '{print $2 }' | grep -q $pid 2> /dev/null; do
    if [ $(expr $(date +%s) - $start) -gt $1 ]; then
      echo "Command timed out after $1 seconds. Exiting." >> ~/build.log
      travis_terminate 1
    fi
  done
  wait $pid
}

travis_terminate() {
  travis_finish build
  pkill -9 -P $$
  exit $1
}

rm -rf   ~/build
mkdir -p ~/build
cd       ~/build

touch ~/build.log; > ~/build.log
touch ~/state.log; > ~/state.log

trap 'travis_finish build' TERM

travis_start build
travis_start 'export'
TRAVIS_PULL_REQUEST=false
TRAVIS_SECURE_ENV_VARS=false
TRAVIS_BUILD_ID=1804636
TRAVIS_BUILD_NUMBER=141
TRAVIS_JOB_ID=1804637
TRAVIS_JOB_NUMBER=141.1
TRAVIS_BRANCH=master
TRAVIS_COMMIT=1e76ebd1108dd918bd0d17c5f241a7984292b31f
TRAVIS_COMMIT_RANGE=ad079609a408...1e76ebd1108d
TRAVIS_RUBY_VERSION=1.9.2
travis_finish 'export'

travis_start 'checkout'
GIT_ASKPASS=echo
echo \$\ git\ clone\ --depth\=100\ --quiet\ git://github.com/travis-ci/travis-support.git\ . >> ~/build.log 2>&1
((git clone --depth=100 --quiet git://github.com/travis-ci/travis-support.git .) >> ~/build.log 2>&1) &
travis_timeout 300
travis_assert
rm -f ~/.ssh/source_rsa
echo \$\ git\ checkout\ -qf\ 1e76ebd1108dd918bd0d17c5f241a7984292b31f >> ~/build.log 2>&1
(git checkout -qf 1e76ebd1108dd918bd0d17c5f241a7984292b31f) >> ~/build.log 2>&1
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
travis_finish 'checkout'

travis_start 'setup'
echo \$\ rvm\ use\ 1.9.2 >> ~/build.log 2>&1
(rvm use 1.9.2) >> ~/build.log 2>&1
travis_assert
if [[ -f Gemfile ]]; then
  BUNDLE_GEMFILE=$pwd/Gemfile
fi
travis_finish 'setup'

travis_start 'announce'
echo \$\ java\ -version >> ~/build.log 2>&1
(java -version) >> ~/build.log 2>&1
echo \$\ javac\ -version >> ~/build.log 2>&1
(javac -version) >> ~/build.log 2>&1
echo \$\ ruby\ --version >> ~/build.log 2>&1
(ruby --version) >> ~/build.log 2>&1
echo \$\ gem\ --version >> ~/build.log 2>&1
(gem --version) >> ~/build.log 2>&1
travis_finish 'announce'

travis_start 'install'
if [[ -f Gemfile ]]; then
  echo \$\ bundle\ install\  >> ~/build.log 2>&1
  ((bundle install ) >> ~/build.log 2>&1) &
  travis_timeout 600
  travis_assert
fi
travis_finish 'install'

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
travis_finish 'script'



echo "\n\nDone. Build script exited with $TRAVIS_TEST_RESULT" >> ~/build.log

travis_terminate $TRAVIS_TEST_RESULT
