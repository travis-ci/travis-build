travis_custom_image() {
  : "${TRAVIS_TEST_RESULT:=86}"
  sudo bash -c "rm -rf /etc && mv /etc_backup /etc && rm -f /etc/google_instance_id /etc/boto.cfg && rm -rf ${TRAVIS_BUILD_DIR}"
  echo -e "\\nBuild done with result: ${TRAVIS_TEST_RESULT}"
  echo -e "\\nCreating custom image ${TRAVIS_CREATED_CUSTOM_IMAGE_NAME}"
  travis_terminate "${TRAVIS_TEST_RESULT}"
}
