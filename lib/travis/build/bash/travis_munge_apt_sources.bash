travis_munge_apt_sources() {
  if ! command -v apt-get &>/dev/null; then
    return
  fi

  local src="${TRAVIS_BUILD_ROOT}/etc/apt/sources.list"
  local tmp_dest="${TRAVIS_TMPDIR}/etc-apt-sources.list"

  if [[ ! -f "${src}" ]]; then
    return
  fi

  local mirror="${TRAVIS_APT_MIRRORS_BY_INFRASTRUCTURE[${TRAVIS_INFRA}]}"
  if [[ ! "${mirror}" ]]; then
    mirror="${TRAVIS_APT_MIRRORS_BY_INFRASTRUCTURE[unknown]}"
  fi

  if [[ ! "${mirror}" ]]; then
    echo -e "${ANSI_YELLOW}No APT mirror found; skipping source munging.${ANSI_RESET}"
    return
  fi

  sed -e "s,http://.*\\.ubuntu\\.com/ubuntu/,${mirror}," \
    "${src}" >"${tmp_dest}"
  sudo mv "${src}" "${src}.travis-build.bak"
  sudo mv "${tmp_dest}" "${src}"
}
