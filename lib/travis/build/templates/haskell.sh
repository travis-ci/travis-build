: "${TRAVIS_GHC_DEFAULT:=<%= default_ghc %>}"
: "${TRAVIS_GHC_ROOT:=<%= root %>/usr/local/ghc}"
if [[ ! -d "${TRAVIS_GHC_ROOT}" && -d '<%= root %>/opt/ghc' ]]; then
  TRAVIS_GHC_ROOT='<%= root %>/opt/ghc'
fi

export TRAVIS_GHC_DEFAULT
export TRAVIS_GHC_ROOT

function travis_ghc_find() {
  local search="${1}"
  local v
  if [[ ! "${search}" ]]; then
    echo "${TRAVIS_GHC_DEFAULT}"
    return 1
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

function travis_ghc_install() {
  local ghc_version="${1}"
  local cabal_version="${2}"
  if [[ ! "${ghc_version}" ]]; then
    return 1
  fi
  if [[ ! "${cabal_version}" ]]; then
    return 1
  fi
  if ! sudo date &>/dev/null; then
    <%# no sudo? no installation %>
    return 1
  fi
  if [[ ! -f '<%= root %>/etc/apt/sources.list.d/hvr-ghc.list' ]]; then
    echo -e "\n${ANSI_GREEN}Adding ppa:hvr/ghc.${ANSI_RESET}"
    sudo apt-add-repository -yq ppa:hvr/ghc
  fi
  sudo apt-get update -yqq
  if sudo apt-get install -yq "ghc-${ghc_version}"; then
    echo -e "\n${ANSI_GREEN}Successfully installed ghc-${ghc_version}.${ANSI_RESET}"
    if sudo apt-get install -yq "cabal-install-${cabal_version}"; then
      echo -e "\n${ANSI_GREEN}Successfully installed cabal-install-${cabal_version}.${ANSI_RESET}"
      return 0
    fi
  fi
  return 1
}
