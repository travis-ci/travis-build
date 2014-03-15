sudo su -c "cat > <%= Addons::BIN_PATH %>/travis-<%= File.basename(filename, '.sh') %>" << "sh"
#!/bin/bash -e

hosts=$@

sed -e 's/^\(127\.0\.0\.1.*\)$/\1 '"$hosts"'/' -i.bak /etc/hosts
sed -e 's/^\(::1.*\)$/\1 '"$hosts"'/' -i.bak /etc/hosts
sh
