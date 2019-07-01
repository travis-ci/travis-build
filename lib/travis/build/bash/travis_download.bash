travis_download() {
  local src="${1}"
  local dst="${2}"

  if curl --version &>/dev/null; then
    curl -fsSL --connect-timeout 1 "${src}" -o "${dst}" 2>/dev/null
    return "${?}"
  fi

  if wget --version &>/dev/null; then
    wget --connect-timeout 1 -q "${src}" -O "${dst}" 2>/dev/null
    return "${?}"
  fi

  return 1
}
