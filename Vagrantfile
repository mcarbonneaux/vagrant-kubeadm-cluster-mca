MASTER_COUNT = 3
NODE_COUNT = 0
IMAGE = "ubuntu/hirsute64"
CILIUM_VERSION = "1.10.1"
CILIUM_PASSWORD = "admin"
K8S_SERVER_IPS = "172.22.101."
K8S_SERVER_MEMORY = 2000
K8S_NODE_MEMORY = 1500
K8S_NODE_IPS = "172.22.101." 
#K8S_VERSION = "1.21.2"
#K8S_VERSION = "1.19.12"
K8S_VERSION = "1.20.8"

Vagrant.configure("2") do |config|

  (1..MASTER_COUNT).each do |i|
    config.vm.define "server-#{i}" do |server|
      server.vm.box = IMAGE
      server.vm.hostname = "server-#{i}"
      server.vm.network  :private_network, ip: K8S_SERVER_IPS+"#{i+100}", nic_type: "82545EM"
      server.vm.provider :virtualbox do |v|
	v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
	v.linked_clone = true 
	v.cpus = 2
	v.memory = K8S_SERVER_MEMORY
	v.name = "server-#{i}"
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
      kubenodes.vm.network  :private_network, ip: K8S_NODE_IPS + "#{i+110}", nic_type: "82545EM"
      kubenodes.vm.provision "file", source: "./.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
      kubenodes.vm.provision "file", source: "./.ssh/id_rsa", destination: "/tmp/id_rsa"
      kubenodes.vm.provision "shell", path: "scripts/configure_k8s_server-kubeadm.sh", args: [K8S_SERVER_IP, CILIUM_PASSWORD]
      kubenodes.vm.provider "virtualbox" do |v|
        v.linked_clone = true
        v.memory = K8S_NODE_MEMORY
        v.name = "node-#{i}"
      end
    end
  end

end
