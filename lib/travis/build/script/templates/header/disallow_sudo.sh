sudo sed -e 's/^%sudo.*//' -i.bak /etc/sudoers
sudo rm /etc/sudoers.bak
sudo rm -f /etc/sudoers.d/travis
# sudo echo 'travis ALL=NOPASSWD: service /usr/local/travis/bin/*' > /etc/sudoers.d/travis

if sudo ls > /dev/null 2>&1; then
  echo "Failed to remove sudo access."
  travis_terminate 2
fi
