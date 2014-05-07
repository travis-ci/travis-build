<%= ERB.new(File.read('lib/travis/build/script/templates/header.sh')).result(binding) %>

stubs=(
  before_install install before_script script after_script after_success after_failure
  android-update-sdk
  git
  gcc make
  java javac
  jdk_switcher
  lein lein2
  rebar
  go gvm
  gradle mvn ant
  ghc cabal ghc_find
  node nvm npm
  perl perlbrew cpanm
  php phpenv phpunit composer
  python pip
  ruby rvm gem bundle rake
  sbt
  curl cp bash mv tar
  /Users/travis/travis-utils/osx-cibuild.sh xcodebuild pod motion xctool osascript
  sudo
  chruby
)
for stub in ${stubs[*]}; do
  eval "$stub() { builtin echo $stub \$@; }"
done

stubs=(
  echo cd rm mkdir source
  travis_start travis_finish travis_assert travis_terminate travis_retry
)
for stub in ${stubs[*]}; do
  eval "$stub() { builtin echo $stub \$@; }"
done
