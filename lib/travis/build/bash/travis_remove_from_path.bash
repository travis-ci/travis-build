travis_remove_from_path() {
  local target="$1"
  echo "path: $PATH"
  echo "java home: $JAVA_HOME"
  PATH="$(echo "$PATH" |
    sed -e "s,\\(:\\|^\\)$target\\(:\\|$\\),:,g" \
      -e 's/::\+/:/g' \
      -e 's/:$//' \
      -e 's/^://')"
}
