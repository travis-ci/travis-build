mkdir -p tmp
cd tmp

function travis_timeout() {
  sleep 0 # no usleep
  sleep 0
  builtin echo travis_timeout $1 >> test.log
}

stubs=( \
  before_install install before_script script after_script after_success after_failure \
  git
  gcc make
  java javac \
  jdk_switcher
  lein lein2
  rebar
  go
  gradle mvn ant
  ghc cabal
  node nvm npm
  perl perlbrew cpanm
  php phpenv phpunit
  python pip
  ruby rvm gem bundle rake \
  sbt
)
for stub in ${stubs[*]}; do
  eval "function $stub() { builtin echo $stub \$@ >> test.log; builtin echo output from $stub \$@; }"
done

stubs=( \
  echo cd rm mkdir source \
  travis_start travis_end travis_assert \
)
for stub in ${stubs[*]}; do
  eval "function $stub() { builtin echo $stub \$@ >> test.log; }"
done
