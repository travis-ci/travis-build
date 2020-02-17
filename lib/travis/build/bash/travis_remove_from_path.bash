travis_remove_from_path() {
  local target="$1"
  PATH="$(echo "$PATH" |
    sed -e "s,\\(:\\|^\\)$target\\(:\\|$\\),:,g" \
      -e 's/::\+/:/g' \
      -e 's/:$//' \
      -e 's/^://')"
}
