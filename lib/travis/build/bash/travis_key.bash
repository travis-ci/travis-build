travis_key() {
  local var_name="TRAVIS_$1"
  base64 -d <<< ${!var_name} > $2
}
