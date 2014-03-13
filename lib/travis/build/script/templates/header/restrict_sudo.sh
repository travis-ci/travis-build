sudo -n su -c "
  sed -e 's/^%.*//' -i.bak /etc/sudoers
  echo 'travis ALL=(ALL) NOPASSWD: /usr/local/travis/bin/*' > /etc/sudoers.d/travis
"

if sudo -n ls > /dev/null 2>&1; then
  echo "Failed to restrict sudo access."
  travis_terminate 2
fi
