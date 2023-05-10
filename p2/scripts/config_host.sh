#!/usr/bin/env bash
#must be inserted in vagrantfile if there is a problem with ip range.
  # config.trigger.before :up, :reload do |trigger|
  #   trigger.info = 'Vagrant up called, we will execute the configuration script for virtual box and check if the network configuration is already done or not.'
  #   trigger.run = {inline: 'sudo ./scripts/config_host.sh'}
  # end

IP="192.168.56.0/8"

if [ ! -f "/etc/vbox/networks.conf" ]; then
    sudo echo "* $IP" > /etc/vbox/networks.conf
    if [ ! $? -eq 0 ]; then
        echo "Something did not work during the creation of the configuration file for virtualbox network. Try again"
    else
        echo "Done."
    fi
else
    echo "/etc/vbox/networks.conf File already exists"
fi