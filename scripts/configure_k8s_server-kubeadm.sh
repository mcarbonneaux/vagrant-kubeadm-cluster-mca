#!/bin/bash -x

. /vagrant/scripts/configure_function.sh

# update repository list
apt-get update

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
cilium_version=${2:-1.10.3}
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
install_consul_server $server_ip $server_max_number $server_number
install_dnsmasq_server $server_max_number
install_dns_forwarder $server_max_number $server_ip
install_haproxy $server_ip

# config kubelet
echo "KUBELET_EXTRA_ARGS='--node-ip=${server_ip}  --container-runtime=$cni_runtime  --cgroup-driver=$cgroup_driver'" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

if [ "$server_number" -eq 1 ]; then
  # create the kubernetes cluster
  configure_kubeadm_create_cluster $server_ip $apiserver_port $k8s_version $server_max_number 
else
  #join the cluster
  configure_kubeadm_join_cluster $server_ip $apiserver_port $k8s_version $server_max_number control-plane
fi

if [ "$server_number" -eq 1 ]; then
  # ajoute les repos a helm
  helm repo add stable https://charts.helm.sh/stable
  helm repo update

  case $k8s_overlay in
    "cilium")
    install_cilium_on_cluster
    ;;
    "calico") 
    kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml
    ;;
    *) # default to flannel
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    ;;
  esac

fi
kubectl get cs
kubectl get node
kubectl version --client -o json | jq "."
kubectl cluster-info

exit 0
