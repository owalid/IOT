#!/bin/bash

echo "Update alpine database and Add curl to it."
sudo apk -U add curl
echo "Installing k3s..."
curl -sfL https://get.k3s.io | sh -
sudo k3s kubectl get node
if [ ! $? -eq 0 ]; then
    echo "Installation of k3s failed. The program will exit."
    exit 1
else
    echo "Everything is fine, cool !"
fi

