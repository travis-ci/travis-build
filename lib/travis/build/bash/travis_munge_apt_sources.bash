travis_munge_apt_sources() {
  if ! command -v apt-get &>/dev/null; then
    return
  fi

  local src="${TRAVIS_ROOT}/etc/apt/sources.list"
  src="${src//\/\//\/}"
  local tmp_dest="${TRAVIS_TMPDIR}/etc-apt-sources.list"
  tmp_dest="${tmp_dest//\/\//\/}"

  if [[ ! -f "${src}" ]]; then
    return
  fi

  local mirror="${TRAVIS_APT_MIRRORS_BY_INFRASTRUCTURE[${TRAVIS_INFRA}]}"
  if [[ ! "${mirror}" ]]; then
    mirror="${TRAVIS_APT_MIRRORS_BY_INFRASTRUCTURE[unknown]}"
  fi

  if [[ ! "${mirror}" ]]; then
    echo -e "${ANSI_YELLOW}No APT mirror found; not updating ${src}.${ANSI_RESET}"
    return
  fi

  echo -e "${ANSI_YELLOW}Setting APT mirror in ${src}: ${mirror}${ANSI_RESET}"

  sed -e "s,http://.*\\.ubuntu\\.com/ubuntu/,${mirror}," \
    "${src}" >"${tmp_dest}"
  sudo mv "${src}" "${src}.travis-build.bak"
  sudo mv "${tmp_dest}" "${src}"
}
