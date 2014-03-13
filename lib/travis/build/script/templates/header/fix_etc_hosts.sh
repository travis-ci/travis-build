sudo sed -e 's/^\(127\.0\.0\.1.*\)$/\1 '`hostname`'/' -i.bak /etc/hosts
rm /etc/hosts.bak
