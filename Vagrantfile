# to test bgp with cilium
# https://docs.cilium.io/en/v1.10/gettingstarted/bgp/#bgp
# https://metallb.universe.tf/
# https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/example-config.yaml

MASTER_COUNT = 3
NODE_COUNT = 0 # change this value to add k8s node
# liste of ubuntu lts : https://wiki.ubuntu.com/Releases
# use last lts vagrant box from https://roboxes.org/
IMAGE = "generic/ubuntu2104"
NETWORK_TYPE = "82545EM"
#NETWORK_TYPE = "virtio"
CILIUM_VERSION = "1.10.3"
CILIUM_CLI_VERSION = "v0.8.6"
CRICTL_VERSION = "v1.20.0"
HUBBLE_VERSION = "v0.8.1"
CILIUM_PASSWORD = "admin"
USER_IPS = "172.22.100."
K8S_SERVER_IPS = "172.22.101."
K8S_SERVER_MEMORY = 2500
K8S_NODE_MEMORY = 1500
K8S_NODE_IPS = "172.22.101." 
#K8S_VERSION = "1.21.2"
#K8S_VERSION = "1.19.12"
K8S_VERSION = "1.20.8"

$change_default_route = <<-SCRIPT
ip route add 172.22.100.0/24 via 172.22.101.2 || true
exit 0
SCRIPT

$addvirtualiptouser = <<-SCRIPT
ip addr add 172.22.100.50/24 dev enp0s8 || true
ip addr add 172.22.100.51/24 dev enp0s8 || true
ip addr add 172.22.100.52/24 dev enp0s8 || true
ip addr add 172.22.100.53/24 dev enp0s8 || true
ip addr add 172.22.100.54/24 dev enp0s8 || true
ip addr add 172.22.100.55/24 dev enp0s8 || true
exit 0
SCRIPT

$enablesshdfromhost = <<-SCRIPT
  sed -ie "s/^PasswordAuthentication.*$/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  systemctl restart sshd
SCRIPT

$removek8snode = <<-SCRIPT
  kubectl cordon $HOSTNAME
  kubectl drain $HOSTNAME
  kubectl delete node $HOSTNAME
SCRIPT

$remountshare = <<-SCRIPT
if  !  type  VBoxControl  > /dev/null;  then
  echo  'VirtualBox Guest Additions NOT found'  > /dev/stderr
  exit 1
fi

MY_UID="$(id -u)"
MY_GID="$(id -g)"

( set -x;  sudo  VBoxControl  sharedfolder  list; )  |  \
grep      '^ *[0-9][0-9]* *- *'                      |  \
sed  -e 's/^ *[0-9][0-9]* *- *//'                    |  \
while  read  SHARED_FOLDER
do
  MOUNT_POINT="/$SHARED_FOLDER"
  if  [ -d "$MOUNT_POINT" ];  then
    MOUNTED="$(mount  |  grep  "$MOUNT_POINT")"
    if  [ "$MOUNTED" ];  then
      echo  "Already mounted :  $MOUNTED"
    else
      (
        set -x
        sudo  mount  -t vboxsf  -o "nosuid,uid=$MY_UID,gid=$MY_GID"  "$SHARED_FOLDER"  "$MOUNT_POINT"
      )
    fi
  fi
done
SCRIPT

$routeaddwin = <<-SCRIPT

 if ((Get-Host).Version.Major -lt 7) {
   if ( (Get-Command pwsh | measure).count -eq 0) {
     echo "you must install power shell 7 before use this script!"
     exit -1;
   }
   $pwshpath=(Get-Command pwsh).Source
   Start-Process -Wait -NoNewWindow -FilePath $pwshpath -ArgumentList  ( '-File', 'routeadd.ps1' )
 }


SCRIPT

$routeaddunix = <<-SCRIPT
  ip route add 10.10.10.0/24 via 172.22.100.2
SCRIPT

$generatesshkey = <<-SCRIPT
  if (-Not (Test-Path .ssh/id_rsa -PathType leaf))
  {
    mkdir -p .ssh
    ssh-keygen -f .ssh/id_rsa -N '""'
  }
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = IMAGE 
  config.ssh.forward_agent = false
  config.vm.boot_timeout = 800
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox", automount: true
  config.trigger.before :up do |trigger|      
	  if Vagrant::Util::Platform.windows? then
	    trigger.info = "generate ssh key..."      
	    trigger.run = {inline: $generatesshkey}    
	  end
  end

  config.vm.provider "virtualbox" do |v|
    v.check_guest_additions = false
  end

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.define "router" do |v|
    v.vm.network :private_network, ip: USER_IPS+"2", nic_type: NETWORK_TYPE
    v.vm.network :private_network, ip: K8S_SERVER_IPS+"2", virtualbox__intnet: "dc_network", :mac=> "001122334455", nic_type: NETWORK_TYPE
    v.vm.hostname = "router"
    v.vbguest.installer_options = { allow_kernel_upgrade: true }
    v.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on",
                                    "--graphicscontroller", "vmsvga" ]
      v.linked_clone = true 
      v.cpus = 2
      v.memory = 512
    end

    v.trigger.after :up do |trigger|      
          trigger.info = "add 10.10.10.0/24 route..."      
	  if Vagrant::Util::Platform.windows? then
            trigger.run = {inline: $routeaddwin}    
	  else
            trigger.run = {inline: $routeaddunix}    
	  end
    end

    #v.vm.provision "Force Remount Share", type: "shell", run: "always", inline: $remountshare   
    v.vm.provision "Enable SSH from Host", type: "shell", run: "always", inline: $enablesshdfromhost   
    v.vm.provision "Enable forwarding and configure router", type: "shell", path: "scripts/configure-vagrant-router.sh"
  end

  config.vm.define "user" do |v|
    v.vbguest.installer_options = { allow_kernel_upgrade: true }
    v.vm.network :private_network, ip: USER_IPS+"3", nic_type: NETWORK_TYPE
    v.vm.hostname = "user"
    v.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on",
                                    "--graphicscontroller", "vmsvga" ]
      v.linked_clone = true 
      v.cpus = 2
      v.memory = 512
    end
    v.vm.provision "add virtual ip", type: "shell", run: "always", inline: $addvirtualiptouser  
    v.vm.provision "Enable SSH from Host", type: "shell", run: "always", inline: $enablesshdfromhost   
    v.vm.provision "Bring up demo client IPs", type: "shell", path: "scripts/configure-vagrant-user.sh"
  end

  (1..MASTER_COUNT).each do |i|
    config.vm.define "server-#{i}" do |server|
      server.vbguest.installer_options = { allow_kernel_upgrade: true }
      server.vm.box = IMAGE
      server.vm.hostname = "server-#{i}"
      server.vm.network  :private_network, ip: K8S_SERVER_IPS+"#{i+100}", virtualbox__intnet: "dc_network", nic_type: NETWORK_TYPE
      server.vm.provider :virtualbox do |v|
	v.customize ["modifyvm", :id, "--natdnshostresolver1", "on",
	                              "--graphicscontroller", "vmsvga" ]
	v.linked_clone = true 
	v.cpus = 2
	v.memory = K8S_SERVER_MEMORY
      end

      # nat using vagrant generic way
      # this nat expose k8s server port on localhost:6443
      # you can use kubeconfig from host to hist url
      server.vm.network "forwarded_port", guest: 6443, host: 6443, auto_correct: true
      server.vm.network "forwarded_port", guest: 8500, host: 8500, auto_correct: true

      server.vm.provision "file", source: "./.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
      server.vm.provision "file", source: "./.ssh/id_rsa", destination: "/tmp/id_rsa"
      server.vm.provision "Force default route to the bgp router", type: "shell", run: "always", inline: $change_default_route 
      #server.vm.provision "Force Remount Share", type: "shell", run: "always", inline: $remountshare   
      server.vm.provision "shell", path: "scripts/configure_k8s_server-kubeadm.sh", args: [CILIUM_PASSWORD, CILIUM_VERSION, K8S_VERSION, "#{i}", MASTER_COUNT, CILIUM_CLI_VERSION, HUBBLE_VERSION, CRICTL_VERSION ]

    end
  end

  (1..NODE_COUNT).each do |i|
    config.vm.define "node-#{i}" do |kubenodes|
      kubenodes.vbguest.installer_options = { allow_kernel_upgrade: true }
      kubenodes.vm.box = IMAGE
      kubenodes.vm.hostname = "node-#{i}"
      kubenodes.vm.network  :private_network, ip: K8S_NODE_IPS + "#{i+110}", virtualbox__intnet: "dc_network", nic_type: NETWORK_TYPE
      kubenodes.vm.provision "file", source: "./.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
      kubenodes.vm.provision "file", source: "./.ssh/id_rsa", destination: "/tmp/id_rsa"
      kubenodes.vm.provision "Force default route to the bgp router", type: "shell", run: "always", inline: $change_default_route 
      kubenodes.vm.provision "shell", path: "scripts/configure_k8s_nodes-kubeadm.sh", args: [CILIUM_PASSWORD, CILIUM_VERSION, K8S_VERSION, "#{i}", MASTER_COUNT, CILIUM_CLI_VERSION, HUBBLE_VERSION, CRICTL_VERSION  ]
      kubenodes.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on",
                                      "--graphicscontroller", "vmsvga" ]
        v.linked_clone = true
        v.memory = K8S_NODE_MEMORY
      end
    end
  end


end
