travis_lock_down_env() {
  if [[ "${#_RO[@]}" -eq 0 ]]; then
    return
  fi

  for env_key in "${_RO[@]}"; do
    declare -rx "${env_key}"
  done
}
