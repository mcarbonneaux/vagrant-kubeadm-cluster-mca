configure_firewall() {
# disable ubuntu firewall
ufw disable

# switch nftable to iptable
# https://v1-17.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#ensure-iptables-tooling-does-not-use-the-nftables-backend
apt-get install -y iptables arptables ebtables
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
update-alternatives --set arptables /usr/sbin/arptables-legacy
update-alternatives --set ebtables /usr/sbin/ebtables-legacy
}

# disable swap
disable_swap () {
swapon -s
swapoff -a
}

# check ebpf mount
config_ebpf_mount () {
if [ $(mount | grep /sys/fs/bpf | wc -l) -eq 0 ]; then
echo "Add BPF mount..."
mount bpffs -t bpf /sys/fs/bpf
cat <<EOF >> /etc/fstab
none /sys/fs/bpf bpf rw,relatime 0 0
EOF
fi
}

# https://kubernetes.io/fr/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#permettre-%C3%A0-iptables-de-voir-le-trafic-pont%C3%A9
install_kernel_module () {
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system
}

# install docker.io
install-docker-io () {
apt-get install -y docker.io
mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=${1}"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl enable docker
systemctl daemon-reload
systemctl restart docker
}

# haproxy k8s api server load balancer based on consul discovery
install_haproxy () {

apt-get install -y haproxy

cp -f /vagrant/haproxy.cfg /etc/haproxy/haproxy-k8s.cfg
sed -ie "s/bind[[:blank:]].*:8443/bind $1:8443/g" /etc/haproxy/haproxy-k8s.cfg
echo CONFIG="/etc/haproxy/haproxy-k8s.cfg" >/etc/default/haproxy

systemctl enable haproxy
systemctl restart haproxy

}

# install dnsmasq to forward resolution to consul dns
install_dnsmasq_forwarder () {

apt-get install -y dnsmasq

if [ "$1" -eq 1 ]; then 
cat <<EOF >/etc/dnsmasq.conf
server=/consul/127.0.0.1#8600
server=10.0.2.3
EOF
else
cat <<EOF >/etc/dnsmasq.conf
server=/consul/172.22.101.101
server=10.0.2.3
EOF
fi

systemctl enable dnsmasq
systemctl restart dnsmasq

sed -ie "s/^#DNS=$/DNS=127.0.0.1/g"  /etc/systemd/resolved.conf

systemctl restart systemd-resolved.service

}


# install docker-ce
install-docker-ce () {
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

# to determine docker version
# >apt-cache madison docker-ce
# https://docs.docker.com/engine/install/ubuntu/#install-docker-engine

apt-get install -y docker-ce=$1 docker-ce-cli=$1 containerd.io
mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=${2}"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl enable docker
systemctl daemon-reload
systemctl restart docker
}

# install helm 3
install_helm3 () {
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
}

# install consul
install_consul() {
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   apt-get install -y consul
   systemctl enable /lib/systemd/system/consul.service
}
install_consul_server() {
  install_consul
consultbootip=$(seq 1 $2 | xargs -I{} -n1 echo "\"172.22.101.10{}\"" | (readarray -t ARRAY; IFS=','; echo "${ARRAY[*]}"))
echo $consultbootip >/vagrant/.consultbootip
cat <<EOF >/etc/consul.d/consul.hcl
data_dir = "/opt/consul"
ui_config{
   enabled = true
}
server = true
bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"172.22.101.0/24\" | attr \"address\" }}"
retry_join = [${consultbootip}]
#bootstrap_expect=1
encrypt = "uHOOH0Wj6LrF6vRbC+zg0Sa6ayzQwZ0ykIxNadmn2Hw="
EOF
if [ "$3" -eq 1 ]; then
  sed -ie "s/#bootstrap_expect=1/bootstrap_expect=1/g" /etc/consul.d/consul.hcl
fi
   systemctl start consul.service
}
install_consul_agent() {
  install_consul
cat <<EOF >/etc/consul.d/consul.hcl
data_dir = "/opt/consul"
bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"172.22.101.0/24\" | attr \"address\" }}"
retry_join = [${consultbootip}]
encrypt = "uHOOH0Wj6LrF6vRbC+zg0Sa6ayzQwZ0ykIxNadmn2Hw="
EOF
   systemctl start consul.service
}

# install cilium cli
install_cilium_cli () {
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}
curl -LO "https://github.com/cilium/hubble/releases/download/$cilium_version/hubble-linux-amd64.tar.gz"
curl -LO "https://github.com/cilium/hubble/releases/download/$cilium_version/hubble-linux-amd64.tar.gz.sha256sum"
sha256sum --check hubble-linux-amd64.tar.gz.sha256sum
tar zxf hubble-linux-amd64.tar.gz
mv hubble /usr/local/bin
}

# install kubeadm, kubectl et kubelet
install_kubetool () {
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -qy kubelet="$1-00" kubeadm="$1-00" kubectl="$1-00"
apt-mark hold kubeadm kubelet kubectl
}

configure_kubeconfig () {
mkdir -p $HOME/.kube                                           
cp -f /vagrant/.kubeconfig $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
chmod 700  $HOME/.kube/config
ln -fs $HOME/.kube ~vagrant/.kube
echo "sudo -sE" >> /home/vagrant/.profile
}

push_certificate () {
  rm -rf /vagrant/.pki
  cp -rp /etc/kubernetes/pki /vagrant/.pki
}

pull_certificate () {
  mkdir -p /etc/kubernetes/pki/ectd
  cp -vrpf /vagrant/.pki/{apiserver,ca,sa,front-proxy-ca}.* /tmp
  cp -vrpf /vagrant/.pki/etcd/ca.* /etc/kubernetes/pki/etcd/
}

# create the kubernetes cluster
configure_kubeadm_create_cluster () {
  server_ip=$1
  apiserver_port=$2
  k8s_version=$3
  server_max_number=$4

cat <<EOF >/etc/consul.d/k8sapi.json
{
  "service": {
  "id": "k8s-api-servers-${server_ip}",
  "name": "k8s-server-api",
  "port": 6443,
  "check": {
    "tcp": "localhost:22",
    "interval": "10s",
    "timeout": "1s"
  }
  }
}
EOF
consul reload

  additionalsan=$(seq 1 $server_max_number | xargs -I{} -n1 echo "server-{},172.22.101.10{}" | (readarray -t ARRAY; IFS=','; echo "${ARRAY[*]}"))

  # pull kubernetes images
  kubeadm config images pull --kubernetes-version=$k8s_version

  CERT_KEY=$(kubeadm certs certificate-key)

  kubeadm init --apiserver-advertise-address=$server_ip \
               --apiserver-bind-port=$apiserver_port \
	       --apiserver-cert-extra-sans "$additionalsan,localhost,k8s-server-api.service.dc1.consul" \
	       --control-plane-endpoint k8s-server-api.service.dc1.consul:8443 \
	       --pod-network-cidr="10.10.0.0/16" \
	       --service-cidr="10.11.0.0/16" \
	       --kubernetes-version=$k8s_version \
               --skip-phases=addon/kube-proxy \
	       --certificate-key $CERT_KEY \
	       --upload-certs


  # share token and ca hash with other node
  kubeadm token list -o json | jq -r 'select(.description |test("kubeadm init")) | .token' >/vagrant/.token
  openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
     openssl dgst -sha256 -hex | sed 's/^.* //' >/vagrant/.cahash
  echo $CERT_KEY >/vagrant/.certkey

  # distribut ca and api certificate
  push_certificate

  # share kubeconfig with other node
  cp -f /etc/kubernetes/admin.conf /vagrant/.kubeconfig

  # share master api ip:port
  echo "k8s-server-api.service.dc1.consul:8443" >/vagrant/.kubeapiserver

  #to fix kubectl get cs error
  sed -ie "/\- \-\-port=0/d" /etc/kubernetes/manifests/kube-controller-manager.yaml \
                          /etc/kubernetes/manifests/kube-scheduler.yaml

  # configure kubeconfig
  configure_kubeconfig

  # permet l'execution de pod sur le master
  kubectl taint nodes --all node-role.kubernetes.io/master-
}


# join the cluster
configure_kubeadm_join_cluster () {
  server_ip=$1
  apiserver_port=$2
  k8s_version=$3
  server_max_number=$4
cat <<EOF >/etc/consul.d/k8sapi.json
{
  "service": {
  "id": "k8s-api-servers-${server_ip}",
  "name": "k8s-server-api",
  "port": 6443,
  "check": {
    "tcp": "localhost:22",
    "interval": "10s",
    "timeout": "1s"
  }
  }
}
EOF
consul reload

  # pull kubernetes images
  kubeadm config images pull --kubernetes-version=$k8s_version

  # retrieve master api certificat
  pull_certificate

  if [ "$5" == "control-plane" ]; then 
  # join the cluster in controle plane mode
  kubeadm join $(cat /vagrant/.kubeapiserver) \
               --token $(cat /vagrant/.token) \
	       --discovery-token-ca-cert-hash sha256:$(cat /vagrant/.cahash) \
               --apiserver-advertise-address=$server_ip \
               --apiserver-bind-port=$apiserver_port \
	       --certificate-key $(cat /vagrant/.certkey) \
	       --control-plane
  else
  # join the cluster
  kubeadm join $(cat /vagrant/.kubeapiserver) \
               --token $(cat /vagrant/.token) \
	       --discovery-token-ca-cert-hash sha256:$(cat /vagrant/.cahash) 
  fi

  # configure kubeconfig
  configure_kubeconfig

  # permet l'execution de pod sur le master
  kubectl taint nodes --all node-role.kubernetes.io/master-
}

install_cilium_on_cluster () {
    helm repo add cilium https://helm.cilium.io/
    helm repo update

cat <<EOF >/tmp/bgp-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: bgp-config
  namespace: kube-system
data:
  config.yaml: |
    peers:
      - peer-address:  172.22.101.2
        peer-asn: 65002
        my-asn: 65006
    address-pools:
      - name: default
        protocol: bgp
        addresses:
          - 10.10.10.0/24
EOF

    kubectl apply -f /tmp/bgp-config.yaml
    helm install cilium cilium/cilium --version $cilium_version \
                                      --namespace kube-system \
				      --set nodeinit.enabled=true \
				      --set hostServices.enabled=false \
				      --set externalIPs.enabled=true \
				      --set nodePort.enabled=true \
				      --set hostPort.enabled=true \
				      --set bgp.enabled=true \
				      --set bgp.announce.loadbalancerIP=true \
				      --set bpf.masquerade=false \
				      --set image.pullPolicy=IfNotPresent \
				      --set ipam.mode=kubernetes \
				      --set kubeProxyReplacement=strict \
				      --set tunnel=disabled \
				      --set autoDirectNodeRoutes=true \
				      --set loadBalancer.algorithm=maglev \
				      --set loadBalancer.mode=dsr \
				      --set loadBalancer.acceleration=native  \
				      --set hubble.listenAddress=":4244" \
				      --set hubble.relay.enabled=true \
				      --set hubble.ui.enabled=true \
				      --set k8sServiceHost=$(cat /vagrant/.kubeapiserver| awk -F':' '{print $1}') \
				      --set k8sServicePort=$(cat /vagrant/.kubeapiserver| awk -F':' '{print $2}')
}
