# vagrant-kubeadm-cilium-ha
Vagrant file to build kubernetes cluster high availibility + cilium + bgp 

Is to test k8s in Multi-tier load-balancing configuration.
- BGP ECMP with cilium/metallb (stateless)
- L4 LoadBlancer DSR with Cilium and ebpf (stateless)
- L7 LoadBlancer in pod (haproxy/envoy or nginx...) (StateFull)

https://vincent.bernat.ch/en/blog/2018-multi-tier-loadbalancer

# Prerequirist

- [vagrant](https://www.vagrantup.com/downloads)
- [virtualbox](https://www.virtualbox.org/wiki/Downloads)
- [git](https://git-scm.com/download/win)

# Start the cluster

```
# git clone https://github.com/mcarbonneaux/vagrant-kubeadm-cluster-mca.git
# cd vagrant-kubeadm-cluster-mca
# mkdir .ssh
# ssh-keygen -f ./.ssh/id_rsa
# vagrant up
```

# To connect to the cluster

```
# vagrant ssh server-<1-3>
```

# Use kubectl

kubectl are already configured and you are sudoed to root.

```
# kubectl get node
```

