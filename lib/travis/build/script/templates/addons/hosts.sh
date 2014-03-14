sudo su -c "cat > <%= Addons::BIN_PATH %>/travis-addon-<%= File.basename(filename, '.sh') %>" << sh
  sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 $@/' -i '' /etc/hosts
  sed -e 's/^\\(::1.*\\)$/\\1 $@/' -i '' /etc/hosts
sh
