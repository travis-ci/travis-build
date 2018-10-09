travis_ghc_setup_env() {
  : "${TRAVIS_GHC_DEFAULT:=7.10.3}"
  : "${TRAVIS_GHC_ROOT:=${TRAVIS_ROOT}/usr/local/ghc}"

  if [[ ! -d "${TRAVIS_GHC_ROOT}" && -d "${TRAVIS_ROOT}/opt/ghc" ]]; then
    TRAVIS_GHC_ROOT="${TRAVIS_ROOT}/opt/ghc"
  fi

  declare -rx TRAVIS_GHC_DEFAULT
  declare -rx TRAVIS_GHC_ROOT
}
