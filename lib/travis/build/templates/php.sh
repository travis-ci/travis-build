<%# munge php.ini configs with correct mysql-5.6 socket path when applicable %>
travis_configure_php_mysql56() {
  if ! grep -qE '^socket = /run/mysql-5.6' <%= home %>/.my.cnf; then
    return
  fi

  local mysql_unix_port
  mysql_unix_port="$(grep ^socket <%= home %>/.my.cnf)"
  mysql_unix_port="${mysql_unix_port##*=}"
  mysql_unix_port="${mysql_unix_port// /}"

  export MYSQL_UNIX_PORT="${mysql_unix_port}"

  if [[ -d <%= home %>/.phpenv/versions ]]; then
    find <%= home %>/.phpenv/versions -name php.ini \
      | while read -r ini_file; do
        sed -i "/^[a-z_]*mysql.*socket/s:\$: ${MYSQL_UNIX_PORT}:" "${ini_file}"
      done
  fi

  if [[ -f '<%= root %>/etc/hhvm/php.ini' ]]; then
    echo "
pdo_mysql.default_socket = ${MYSQL_UNIX_PORT}
mysqli.default_socket = ${MYSQL_UNIX_PORT}
hhvm.mysql.socket = ${MYSQL_UNIX_PORT}
" | sudo tee -a '<%= root %>/etc/hhvm/php.ini' >/dev/null
  fi
}
