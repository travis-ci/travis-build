sudo su -c "cat > <%= Addons::BIN_PATH %>/travis-<%= File.basename(filename, '.sh') %>" << "sh"
#!/bin/bash -e

version=$1

echo -e "\033[33;1mInstalling Firefox v$version\033[0m"

mkdir -p /usr/local/firefox-$version
chown -R travis /usr/local/firefox-$version
wget -O /tmp/firefox.tar.bz2 http://ftp.mozilla.org/pub/firefox/releases/$version/linux-x86_64/en-US/firefox-$version.tar.bz2

cwd=$(pwd)
cd /usr/local/firefox-$version
tar xf /tmp/firefox.tar.bz2
ln -sf /usr/local/firefox-$version/firefox/firefox /usr/local/bin/firefox
ln -sf /usr/local/firefox-$version/firefox/firefox-bin /usr/local/bin/firefox-bin
cd $cwd
sh
