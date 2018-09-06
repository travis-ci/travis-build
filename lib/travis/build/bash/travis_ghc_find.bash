travis_ghc_find() {
  local search="${1}"
  local v
  if [[ ! "${search}" ]]; then
    echo -e "${ANSI_RED}No ghc version given.${ANSI_RESET}" >&2
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
    echo -e "${ANSI_RED}No such ghc version '${search}'.${ANSI_RESET}" >&2
  fi
  echo -e "${ANSI_YELLOW}Using default ghc version '${TRAVIS_GHC_DEFAULT}'.${ANSI_RESET}" >&2
  echo "${TRAVIS_GHC_DEFAULT}"
  return 1
}
