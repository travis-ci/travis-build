travis_custom_image() {
  sudo mv /etc_backup /etc
  echo -e "\\nCreating custom image ${TRAVIS_CREATED_CUSTOM_IMAGE_NAME}"
  while :; do
    echo -n '.'
  done
}
