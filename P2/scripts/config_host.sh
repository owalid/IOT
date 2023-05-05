#!/usr/bin/env bash

IP=""

if [ ! -f "/etc/vbox/networks.conf" ]; then
    sudo echo "* 192.168.56.0/8" > /etc/vbox/networks.conf
    if [ ! $? -eq 0 ]; then
        echo "Something did not work during the creation of the configuration file for virtualbox network. Try again"
    else
        echo "Done."
    fi
else
    echo "File already exists"
fi