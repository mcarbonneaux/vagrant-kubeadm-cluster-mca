# vagrant-kubeadm-cilium-ha
Vagrant file to build kubernetes cluster high availibility + cilium + bgp 

Is to test k8s in Multi-tier load-balancing configuration.
- BGP ECMP with cilium/metallb (stateless)
- L4 LoadBlancer DSR with Cilium and ebpf (stateless)
- L7 LoadBlancer in pod (haproxy/envoy or nginx...) (StateFull)

https://vincent.bernat.ch/en/blog/2018-multi-tier-loadbalancer

# prerequirist

- [vagrant](https://www.vagrantup.com/downloads)
- [virtualbox](https://www.virtualbox.org/wiki/Downloads)

# start the cluster

```
# git clone https://github.com/mcarbonneaux/vagrant-kubeadm-cilium-ha.git
# vagrant up
```

# to connect to the cluster

```
# vagrant ssh server-<1-3>
```

# use kubectl

kubectl are already configured and you are sudoed to root.

```
# kubectl get node
```

