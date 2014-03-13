if sed --version 2> /dev/null | grep GNU > /dev/null; then
  sed_inline="-i"
else
  sed_inline="-i ''"
fi
sudo sed -e 's/^\(127\.0\.0\.1.*\)$/\1 '`hostname`'/' $sed_inline /etc/hosts
