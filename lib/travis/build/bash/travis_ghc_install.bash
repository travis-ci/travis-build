travis_ghc_install() {
  local ghc_version="${1}"
  local cabal_version="${2}"
  if [[ ! "${ghc_version}" ]]; then
    echo -e "\\n${ANSI_RED}No ghc version given.${ANSI_RESET}" >&2
    return 1
  fi
  if [[ ! "${cabal_version}" ]]; then
    echo -e "\\n${ANSI_RED}No cabal version given.${ANSI_RESET}" >&2
    return 1
  fi
  if ! sudo date &>/dev/null; then
    return 1
  fi
  if [[ ! -f '<%= root %>/etc/apt/sources.list.d/hvr-ghc.list' ]]; then
    echo -e "\\n${ANSI_GREEN}Adding ppa:hvr/ghc.${ANSI_RESET}" >&2
    sudo apt-add-repository -y ppa:hvr/ghc
  fi
  travis_apt_get_update
  if sudo apt-get install -yq "ghc-${ghc_version}"; then
    echo -e "\\n${ANSI_GREEN}Successfully installed 'ghc-${ghc_version}'.${ANSI_RESET}" >&2
  else
    return 1
  fi
  if sudo apt-get install -yq "cabal-install-${cabal_version}"; then
    echo -e "\\n${ANSI_GREEN}Successfully installed 'cabal-install-${cabal_version}'.${ANSI_RESET}" >&2
    return 0
  fi
  return 1
}
