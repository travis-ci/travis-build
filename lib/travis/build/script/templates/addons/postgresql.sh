sudo su -c "cat > <%= Addons::BIN_PATH %>/travis-addon-<%= File.basename(filename, '.sh') %>" << "sh"
#!/bin/bash -e

version=$1

export PATH="/usr/lib/postgresql/$version/bin:$PATH"
echo -e "\033[33;1mStart PostgreSQL v$version\033[0m"
service postgresql stop
service postgresql start $version
sh
