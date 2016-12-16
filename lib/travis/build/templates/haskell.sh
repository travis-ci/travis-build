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
  local search="${1}"
  if ! sudo date &>/dev/null; then
    <%# no sudo? no installation %>
    return 1
  fi
  if [[ ! -f '<%= root %>/etc/apt/sources.list.d/hvr-ghc.list' ]]; then
    sudo apt-add-repository -yq ppa:hvr/ghc
  fi
  sudo apt-get update -yqq
  if sudo apt-get install -yq "ghc-${1}"*; then
    echo -e "\n${ANSI_GREEN}Successfully installed GHC version =~ ${1}.${ANSI_RESET}"
    return 0
  fi
  echo -e "\n${ANSI_RED}Failed to install GHC version =~ ${1}.${ANSI_RESET}"
  return 1
}
