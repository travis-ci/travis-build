sudo -n sed -e 's/^\(127\.0\.0\.1.*\)$/\1 '`hostname`'/' -i.bak /etc/hosts
sudo -n rm /etc/hosts.bak
