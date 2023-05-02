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

Configure box

```vagrantFile
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/bionic64"
  config.vm.box_version = "1.0.282"
  config.vm.box_url = "https://vagrantcloud.com/hashicorp/bionic64"
end
```

Run shell script (script.sh) during install

```vagrantFile
Vagrant.configure("2") do |config|
  config.vm.provision :shell, path: "script.sh"
end
```


Port forwarding

```vagrantFile
Vagrant.configure("2") do |config|
  config.vm.network :forwarded_port, guest: 80, host: 4567
end
```

