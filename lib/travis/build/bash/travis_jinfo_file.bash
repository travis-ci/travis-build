travis_jinfo_file() {
  local vendor version
  vendor="$1"
  version="$2"
  if [[ "$vendor" == oracle ]]; then
    echo ".java-${version}-${vendor}.jinfo"
  elif [[ "$vendor" == openjdk ]]; then
    echo ".java-1.${version}.*-${vendor}-*.jinfo"
  fi
}
