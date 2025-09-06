travis_setup_mssql_server() {
  local mssql_version="${1}"

  local ubuntu_version

  case "${TRAVIS_DIST}" in
  trusty)
    echo -e "${ANSI_RED}Ubuntu 14.04 (Trusty Tahr) not supported.${ANSI_CLEAR}"
    ;;
  xenial)
    ubuntu_version='16.04'
    ;;
  bionic)
    echo -e "${ANSI_RED}Ubuntu 18.04 (Bionic Beaver) not supported.${ANSI_CLEAR}"
    ;;
  *)
    echo -e "${ANSI_RED}Unrecognized operating system.${ANSI_CLEAR}"
    ;;
  esac

  if [[ -z "${mssql_version}" ]]; then
    mssql_version='2017'
  fi

  # install
  echo -e "${ANSI_YELLOW}Installing MssqlServer $mssql_version ${ANSI_CLEAR}"

  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
  curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

  local package_uri="https://packages.microsoft.com/config/ubuntu/${ubuntu_version}"
  sudo add-apt-repository "$(wget -qO- ${package_uri}/mssql-server-${mssql_version}.list)"
  curl ${package_uri}/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list

  sudo apt-get update
  sudo env ACCEPT_EULA=Y apt-get install -y mssql-server
  sudo env ACCEPT_EULA=Y apt install -y msodbcsql17
  sudo env ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev

  export PATH="$PATH:/opt/mssql-tools/bin"

  # start server
  echo -e "${ANSI_YELLOW}Starting MssqlServer${ANSI_CLEAR}"
  sudo env MSSQL_SA_PASSWORD="Password1!" /opt/mssql/bin/mssql-conf -n setup accept-eula
  systemctl status mssql-server --no-pager

  # set no password
  sqlcmd -l 0 -S localhost -U SA -P Password1! -Q "alter login [sa] with CHECK_POLICY=OFF"
  sqlcmd -l 0 -S localhost -U SA -P Password1! -Q "alter login [sa] with PASSWORD=N''"
}
