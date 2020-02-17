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

  local mirror
  for entry in "${_TRAVIS_APT_MIRRORS_BY_INFRASTRUCTURE[@]}"; do
    if [[ "${entry%%::*}" == "${TRAVIS_INFRA}" ]]; then
      mirror="${entry##*::}"
    fi
  done

  if [[ ! "${mirror}" ]]; then
    return
  fi

  sed -e "s,http://.*\\.ubuntu\\.com/ubuntu/,${mirror}," \
    "${src}" >"${tmp_dest}"
  sudo mv "${src}" "${src}.travis-build.bak"
  sudo mv "${tmp_dest}" "${src}"
}
