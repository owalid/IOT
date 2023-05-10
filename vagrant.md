# Vagrant cheat sheet

## Definitions:

Box

> Instead of building a virtual machine from scratch, which would be a slow and tedious process, Vagrant uses a base image to quickly clone a virtual machine. These base images are known as "boxes" in Vagrant, and specifying the box to use for your Vagrant environment is always the first step after creating a new Vagrantfile.

## Commands:

Start VM

```
vagrant up
```

Remove VM

```
vagrant destroy
```

Ssh to machine

```
vagrant ssh
```

Reload config

```
vagrant reload
```

Add box

Box catalog: https://app.vagrantup.com/boxes/search
```
vagrant box add <BOX_NAME>
```

## Config:

**Configure box**

```vagrantFile
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/bionic64"
  config.vm.box_version = "1.0.282"
  config.vm.box_url = "https://vagrantcloud.com/hashicorp/bionic64"
end
```

**Run shell script (script.sh) during install**

```vagrantFile
Vagrant.configure("2") do |config|
  config.vm.provision :shell, path: "script.sh"
end
```


**Port forwarding**

```vagrantFile
Vagrant.configure("2") do |config|
  config.vm.network :forwarded_port, guest: 80, host: 4567
end
```

**Private Network**

```vagrantfile
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "192.168.33.110"
end
```

> Tips : By default, vbox allow ip in range 192.168.56.0/21. If we want to change this ip range, we must provide a network.conf file inside /etc/vbox/.
> For example, to allow 192.168.33.0/8 (and therefore have only the last 8 bytes to allow an ip address), we can add this in the network.conf:
> `* 192.168.33.0/8`
> Now, because we want to create this file _before_ the vms are up, or destroyed etc., we need to add a trigger block inside the vagrantfile:
```vagrantfile
Vagrant.configure("2") do |config|
  config.trigger.before :COMMAND do |trigger|
    trigger.info = 'usefull info'
    trigger.run = {inline: 'sudo ./myscript.sh'}
  end
end
```
> We can use the same method to add after a COMMAND.
