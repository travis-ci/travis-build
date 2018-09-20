travis_ghc_setup_env() {
  : "${TRAVIS_GHC_DEFAULT:=7.10.3}"
  : "${TRAVIS_GHC_ROOT:=${TRAVIS_ROOT}/usr/local/ghc}"

  export TRAVIS_GHC_DEFAULT
  export TRAVIS_GHC_ROOT

  if [[ ! -d "${TRAVIS_GHC_ROOT}" && -d "${TRAVIS_ROOT}/opt/ghc" ]]; then
    export TRAVIS_GHC_ROOT="${TRAVIS_ROOT}/opt/ghc"
  fi
}
