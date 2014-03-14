cat << sh > /usr/local/travis/bin/travis-addon-<%= File.basename(filename, '.sh') %>
  export PATH="/usr/lib/postgresql/$version/bin:$PATH"
  echo -e \"\033[33;1mStart PostgreSQL v$version\033[0m\"; "
  sudo service postgresql stop
  sudo service postgresql start $version
sh
