#!/bin/sh
sudo apt update
sudo apt install curl -y
curl -sfL https://get.k3s.io | sh -s - agent\
  --server=https://192.168.56.110:6443 \
  --token=$(cat /vagrant/token)
