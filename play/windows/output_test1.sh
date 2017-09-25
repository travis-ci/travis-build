$ bash test.sh
test.sh: line 1: ﻿#!/bin/bash: No such file or directory # no bin/bash!

# we can replace pgrep with ps -aux | grep (possibly after a grep install!)
/c/Users/renee/.travis/job_stages: line 21: pgrep: command not found
/c/Users/renee/.travis/job_stages: line 21: pgrep: command not found
/c/Users/renee/.travis/job_stages: line 567: pgrep: command not found
Build system information
Build language: generic
Build id: 1
Job id: 1
Runtime kernel version: 2.8.2(0.313/5/3)

# Skip appliances
/c/Users/renee/.travis/job_stages: line 874: sudo: command not found
/c/Users/renee/.travis/job_stages: line 876: sudo: command not found
/c/Users/renee/.travis/job_stages: line 887: sudo: command not found
/c/Users/renee/.travis/job_stages: line 888: sudo: command not found
/c/Users/renee/.travis/job_stages: line 889: sudo: command not found
/c/Users/renee/.travis/job_stages: line 897: sudo: command not found

# Skip rvm after_use for the patch that we don't need.
/c/Users/renee/.travis/job_stages: line 934: /c/Users/renee/.rvm/hooks/after_use       : No such file or directory
chmod: cannot access '/c/Users/renee/.rvm/hooks/after_use': No such file or dire       ctory

$ git -C travis-ci/travis-support fetch origin
warning: redirecting to https://github.com/travis-ci/travis-support.git/

travis_time:end:21ea184c:start=1506355157934462000,finish=1506355159531006900,du       $ git -C travis-ci/travis-support reset --hard
HEAD is now at a214c21 Merge branch 'master' of github.com:travis-ci/travis-supp       ort
$ cd travis-ci/travis-support
$ git checkout -qf a214c21
$ bash -c 'echo $BASH_VERSION'
4.4.12(1)-release
$ echo "foo"
foo

travis_time:end:1a5ca23c:start=1506355169695124800,finish=1506355169818498800,du
The command "echo "foo"" exited with 0.

Done. Your build exited with 0.

# This can also use ps -aux |  grep to finish the custom kill all 
/c/Users/renee/.travis/job_stages: line 709: pgrep: command not found

renee@windows-test-1 MINGW64 ~/Desktop
$
