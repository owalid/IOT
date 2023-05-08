#!/bin/sh
sudo apt update
sudo apt install curl -y
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip=192.168.56.110
cat /var/lib/rancher/k3s/server/token > /vagrant/token