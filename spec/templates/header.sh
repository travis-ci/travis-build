<%= ERB.new(File.read('lib/travis/build/script/templates/header.sh')).result(binding) %>

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
  curl cp
  /Users/travis/travis-utils/osx-cibuild.sh xcodebuild pod motion
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
