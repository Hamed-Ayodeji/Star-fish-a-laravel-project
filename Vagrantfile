# -*- mode: ruby -*-
# vi: set ft=ruby :

# Deployment of two Ubuntu-based servers, named Master and Slave using vagrant.

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-20.04"
  config.vm.define "Master" do |master|
    master.vm.hostname = "Master"
    master.vm.network "private_network", ip: "192.168.56.20"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = "2"
    end
    master.vm.provision "shell", path: "./ansible-playbook/deploy.sh"
  end
  config.vm.define "Slave" do |slave|
    slave.vm.hostname = "Slave"
    slave.vm.network "private_network", ip: "192.168.56.21"
    slave.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
    end
  end
end