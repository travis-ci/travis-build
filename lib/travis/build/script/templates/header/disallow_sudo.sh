sudo rm -f /etc/sudoers.d/travis
if sudo ls > /dev/null 2>&1; then
  echo "Failed to remove sudo access."
  travis_terminate 2
fi
