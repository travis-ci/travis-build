sudo -n sed -e 's/^%sudo.*//' -i.bak /etc/sudoers
sudo -n rm /etc/sudoers.bak
sudo -n rm -f /etc/sudoers.d/travis

if sudo -n ls > /dev/null 2>&1; then
  echo "Failed to remove sudo access."
  travis_terminate 2
fi
