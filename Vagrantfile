# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "centos/7"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options. Type: virtualbox share data
  # instead of copy (default bheavior).
  #
  # See https://github.com/mitchellh/vagrant/issues/7157
  #
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
   config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
     vb.gui = false
  #
  #   # Customize the amount of memory on the VM:
     vb.memory = "2048"
     vb.cpus = 4
     #vb.customize ["modifyvm", :id, "--vram", "256"]
     # See http://plvision.eu/deploying-intel-dpdk-in-oracle-virtualbox/
     vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.1", "1"]
     vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.2", "1"]
     vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
   end
  #

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    sudo yum update -y
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y  net-tools nmap-ncat libpcap-devel wget pciutils lshw
    # Exclude cpu 2,3 from kernel scheduler
    #   - https://wiki.centos.org/HowTos/Grub2
    # if ! grep isolcpus /etc/default/grub > /dev/null ; then
      # echo
      # echo "Modify GRUB to exclude cpu 2,3 from kernel"
      # echo
      # sudo sed -i -e 's|GRUB_CMDLINE_LINUX="|GRUB_CMDLINE_LINUX="isolcpus=2,3 |g' /etc/default/grub
      # sudo grub2-mkconfig -o /boot/grub2/grub.cfg
      # echo "Reboot to exclude cpu(s) from kernel scheduler"
      # sudo /sbin/reboot
    # fi

    # last
    echo " Login with: vagrant ssh (user: vagrant password: vagrant)"

  SHELL


  # Create a private network, which allows host-only access to the machine
  # See supported network https://github.com/mitchellh/vagrant/blob/master/plugins/providers/virtualbox/action/network.rb#L65
  # Vbox network https://www.virtualbox.org/manual/ch06.html#networkingmodes
  #
  # IMPORTANT: Use two different name: vboxnet0 and vboxnet1 to isolate traffic and avoid multicast on different cards
  
  # --------- SENDER ----------                   ------ RECEIVER -----------------
  # pktgen | -> mac:080020000001 -> (vboxnet0) ->  mac:080020000003 -> | L2 fwd back
  # pktgen | <- mac:080020000002 <- (vboxnet1) <-  mac:080020000004 <- | L2 fwd back
  # 
  # I guess this emulate two direct connection between 

  config.vm.define "sender" do |sender|
    #sender.vm.box = "sender"
    sender.vm.network "private_network", mac: "080020000001",   ip: "10.0.20.101", name: "vboxnet0", nic_type: "82545EM" #, auto_config: false, type: "static"
    sender.vm.network "private_network", mac: "080020000002",   ip: "10.0.50.102", name: "vboxnet1", nic_type: "82545EM" #, auto_config: false, type: "static"

  end

  config.vm.define "receiver" do |receiver|
    #receiver.vm.box = "receiver"
    receiver.vm.network "private_network", mac: "080020000003",   ip: "10.0.20.103", name: "vboxnet0", nic_type: "82545EM" #, auto_config: false, type: "static"
    receiver.vm.network "private_network", mac: "080020000004",   ip: "10.0.50.104", name: "vboxnet1", nic_type: "82545EM" #, auto_config: false, type: "static"

  end
end
