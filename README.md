# Vagrant kubeadm+cilium+ha
Vagrant file to build kubernetes cluster high availibility + cilium

# Prerequirist

- [vagrant](https://www.vagrantup.com/downloads)
- [virtualbox](https://www.virtualbox.org/wiki/Downloads)

# Start the cluster

```
# git clone https://github.com/mcarbonneaux/vagrant-kubeadm-cilium-ha.git
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

