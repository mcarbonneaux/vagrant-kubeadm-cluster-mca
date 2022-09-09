#!/bin/bash -x

. /vagrant/scripts/configure_function.sh

disable_ipv6

# update repository list
configure_update

# install somme common tool needed
apt-get -y  install \
	    apt-transport-https \
	    ca-certificates \
	    curl \
	    gnupg \
	    jq \
	    lsb-release

admin_password=${1:-password}
# k8s version
# curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages | grep Version | awk '{print $2}'
k8s_version=${3:-1.20.8}
crictl_version=${8:-v1.20.0}
cilium_version=${2:-v1.10.1}
cilium_cli_version=${6:-v0.8.6}
hubble_version=${7:-v0.8.1}
server_number=$4
server_max_number=$5
apiserver_port=6443
cgroup_driver="systemd" # systemd, cgroupfs
cni_runtime="docker" # docker and next cri-o
k8s_overlay="cilium" # cilium, calico, flannel
server_ip=$(ip --json -p addr show | jq -r '.[].addr_info[] | select(.local |test("172.22.")) | .local')
export DEBIAN_FRONTEND=noninteractive

# change server ip in host
sed -ie  "s#127.0.2.1[[:blank:]]*"$HOSTNAME"[[:blank:]]"$HOSTNAME"#"$server_ip" "$HOSTNAME"#g"  /etc/hosts

vboxautomountatreboot
configure_firewall
disable_swap
install_kernel_module

# install ubuntu docker version
install-docker-io  $cgroup_driver

# install docker-ce version
# to determine docker version
# >apt-cache madison docker-ce
# https://docs.docker.com/engine/install/ubuntu/#install-docker-engine
# on ubuntu hirsute
#install-docker-ce "5:20.10.7~3-0~ubuntu-hirsute" $cgroup_driver
# on ubuntu focal
#install-docker-ce "5:19.03.15~3-0~ubuntu-focal" $cgroup_driver

install_helm3
install_cilium_cli $cilium_cli_version $hubble_version
install_kubetool $k8s_version
install_consul_agent $server_ip $server_max_number $server_number
install_dns_forwarder $server_max_number
install_haproxy

# config kubelet
echo "KUBELET_EXTRA_ARGS='--node-ip=${server_ip}  --container-runtime=$cni_runtime  --cgroup-driver=$cgroup_driver'" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

#join the cluster
configure_kubeadm_join_cluster $server_ip $apiserver_port $k8s_version $server_max_number 

kubectl get cs
kubectl get node
kubectl version --client -o json | jq "."
kubectl cluster-info

exit 0
