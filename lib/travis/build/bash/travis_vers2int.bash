travis_vers2int() {
  local args
  read -r -a args <<<"$(echo "${1}" | grep --only '^[0-9\.][0-9\.]*' | tr '.' ' ')"
  printf '1%03d%03d%03d%03d' "${args[@]}"
}
