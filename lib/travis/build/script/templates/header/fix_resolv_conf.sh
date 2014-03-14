if ! grep '199.91.168' /etc/resolv.conf > /dev/null; then
  echo -e "nameserver 199.91.168.70\nnameserver 199.91.168.71" | sudo tee /etc/resolv.conf &> /dev/null
fi
