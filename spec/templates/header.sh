mkdir -p tmp
cd tmp

travis_timeout() {
  wait $!
  builtin echo travis_timeout $1
}

stubs=(
  before_install install before_script script after_script after_success after_failure
  git
  gcc make
  java javac
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
  ruby rvm gem bundle rake
  sbt
  xcodebuild pod
)
for stub in ${stubs[*]}; do
  eval "$stub() { builtin echo $stub \$@; }"
done

stubs=(
  echo cd rm mkdir source
  travis_start travis_finish travis_assert travis_terminate
)
for stub in ${stubs[*]}; do
  eval "$stub() { builtin echo $stub \$@; }"
done
