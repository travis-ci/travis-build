travis_key() {
  local var_name="TRAVIS_$1"
  echo ${!var_name} | base64 --decode > $2
}
