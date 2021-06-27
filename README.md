# vagrant-kubeadm-cilium-ha
Vagrant file to build kubernetes cluster high availibility + cilium

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

