Vagrant.configure("2") do |config|

  # set VM specs
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end
 
  # vault node
  config.vm.define "vault" do |vault|
    vault.vm.box = "achuchulev/xenial64"
    vault.vm.box_version = "0.0.1"
    vault.vm.hostname = "node01"
    vault.vm.network "private_network", ip: "192.168.2.10"
    vault.vm.network "forwarded_port", guest: 8200, host: 8200
    vault.vm.provision :shell, :path => "scripts/provision.sh"
    vault.vm.provision :shell, :path => "scripts/vault.sh", run: "always"
    vault.vm.provision :shell, :path => "scripts/setup-ca.sh", run: "always"
    vault.vm.synced_folder ".", "/vagrant", disabled: false
  end
  
end
