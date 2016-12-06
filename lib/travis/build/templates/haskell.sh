: "${TRAVIS_GHC_DEFAULT:=<%= default_ghc %>}"
: "${TRAVIS_GHC_ROOT:=<%= root %>/usr/local/ghc}"
if [[ ! -d "${TRAVIS_GHC_ROOT}" && -d '<%= root %>/opt/ghc' ]]; then
  TRAVIS_GHC_ROOT='<%= root %>/opt/ghc'
fi

function travis_ghc_find() {
  local search="${1}"
  local v
  if [[ ! "${search}" ]]; then
    echo "${TRAVIS_GHC_DEFAULT}"
  else
    for v in "${TRAVIS_GHC_ROOT}"/*/; do
      v=${v%%/}
      v=${v##*/}
      if [[ ! -d "${TRAVIS_GHC_ROOT}/${v}" ]]; then
        continue
      fi
      if [[ "${v}" == ${search}* ]]; then
        echo "${v}"
        return 0
      fi
    done
    echo "travis_ghc_find: error, no such version ${search}" >&2
    echo "travis_ghc_find: using default version ${TRAVIS_GHC_VERSIONS}" >&2
    echo "${TRAVIS_GHC_DEFAULT}"
    return 1
  fi
}
