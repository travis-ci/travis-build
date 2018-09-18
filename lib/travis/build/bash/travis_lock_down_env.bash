travis_lock_down_env() {
  if [[ "${#_TRAVIS_READONLY_VARS[@]}" -eq 0 ]]; then
    return
  fi

  for env_key in "${_TRAVIS_READONLY_VARS[@]}"; do
    declare -rx "${env_key}"
  done
}
