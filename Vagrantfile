MASTER_COUNT = 3
NODE_COUNT = 0
IMAGE = "ubuntu/hirsute64"
CILIUM_VERSION = "1.10.1"
CILIUM_PASSWORD = "admin"
USER_IPS = "172.22.100."
K8S_SERVER_IPS = "172.22.101."
K8S_SERVER_MEMORY = 2000
K8S_NODE_MEMORY = 1500
K8S_NODE_IPS = "172.22.101." 
#K8S_VERSION = "1.21.2"
#K8S_VERSION = "1.19.12"
K8S_VERSION = "1.20.8"

Vagrant.configure("2") do |config|
  config.vm.box = IMAGE 
  config.ssh.forward_agent = false

  config.vm.define "router" do |v|
    v.vm.network :private_network, ip: USER_IPS+"2", virtualbox__intnet: "user_network"
    v.vm.network :private_network, ip: K8S_SERVER_IPS+"2", virtualbox__intnet: "dc_network", :mac=> "001122334455"
    v.vm.hostname = "router"
    v.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.linked_clone = true 
      v.cpus = 1
      v.memory = 512
    end
    v.vm.provision "Enable forwarding and configure router", type: "shell", path: "scripts/configure-vagrant-router.sh"
  end

  config.vm.define "user" do |v|
    v.vm.network :private_network, ip: USER_IPS+"3", virtualbox__intnet: "user_network"
    v.vm.hostname = "user"
    v.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.linked_clone = true 
      v.cpus = 1
      v.memory = 512
    end
    v.vm.provision "Bring up demo client IPs", type: "shell", path: "scripts/configure-vagrant-user.sh"
  end

  (1..MASTER_COUNT).each do |i|
    config.vm.define "server-#{i}" do |server|
      server.vm.box = IMAGE
      server.vm.hostname = "server-#{i}"
      server.vm.network  :private_network, ip: K8S_SERVER_IPS+"#{i+100}", virtualbox__intnet: "dc_network", nic_type: "82545EM"
      server.vm.provider :virtualbox do |v|
	v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
	v.linked_clone = true 
	v.cpus = 2
	v.memory = K8S_SERVER_MEMORY
      end
      server.vm.provision "file", source: "./.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
      server.vm.provision "file", source: "./.ssh/id_rsa", destination: "/tmp/id_rsa"
      server.vm.provision "shell", path: "scripts/configure_k8s_server-kubeadm.sh", args: [CILIUM_PASSWORD, CILIUM_VERSION, K8S_VERSION, "#{i}", MASTER_COUNT]
    end
  end

  (1..NODE_COUNT).each do |i|
    config.vm.define "node-#{i}" do |kubenodes|
      kubenodes.vm.box = IMAGE
      kubenodes.vm.hostname = "node-#{i}"
      kubenodes.vm.network  :private_network, ip: K8S_NODE_IPS + "#{i+110}", virtualbox__intnet: "dc_network", nic_type: "82545EM"
      kubenodes.vm.provision "file", source: "./.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
      kubenodes.vm.provision "file", source: "./.ssh/id_rsa", destination: "/tmp/id_rsa"
      kubenodes.vm.provision "shell", path: "scripts/configure_k8s_nodes-kubeadm.sh", args: [CILIUM_PASSWORD, CILIUM_VERSION, K8S_VERSION, "#{i}", MASTER_COUNT]
      kubenodes.vm.provider "virtualbox" do |v|
        v.linked_clone = true
        v.memory = K8S_NODE_MEMORY
      end
    end
  end


# to test bgp with cilium
# https://docs.cilium.io/en/v1.10/gettingstarted/bgp/#bgp
# https://metallb.universe.tf/
# https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/example-config.yaml

end