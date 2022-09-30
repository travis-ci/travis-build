travis_key() {
  local var_name="TRAVIS_$1"
  if [[ ! -z ${!var_name+x} ]]
  then
    echo "${!var_name}" | base64 --decode > "$2"
    chmod 0600 "$2"
  else
    echo "Required keys " "$1" " was not found. Please verify your account settings or correct build configuration."
    exit 1
  fi
}
