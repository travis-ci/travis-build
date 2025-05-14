travis_custom_image() {
  : "${TRAVIS_TEST_RESULT:=86}"
  sudo mv /etc_backup /etc
  echo -e "\\nCreating custom image ${TRAVIS_CREATED_CUSTOM_IMAGE_NAME}"
  travis_terminate "${TRAVIS_TEST_RESULT}"
}
