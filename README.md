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

# to create simple web pod (nginx) with loadbalancer dsr

the k8s cluster are already configured to support loadbalancer type.

you need juste to create pod with loadbalancer type.

- https://docs.cilium.io/en/v1.10/gettingstarted/bgp/#create-loadbalancer-and-backend-pods


```
apiVersion: v1
kind: Service
metadata:
  name: test-lb
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    svc: test-lb
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      svc: test-lb
  template:
    metadata:
      labels:
        svc: test-lb
    spec:
      containers:
      - name: web
        image: nginx
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
```

```
#  kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP      10.11.0.1       <none>        443/TCP        53m
test-lb      LoadBalancer   10.11.180.200   10.10.10.1    80:31490/TCP   46m
```

you can seen your lb as external ip : 10.10.10.1

# to test the loadbalancer dsr throug the bgp router

```
# vagrant ssh user
# sudo -s
# curl -v http://10.10.10.1 --interface 172.22.100.3
# curl -v http://10.10.10.1 --interface 172.22.100.50
# curl -v http://10.10.10.1 --interface 172.22.100.51
# curl -v http://10.10.10.1 --interface 172.22.100.52
# curl -v http://10.10.10.1 --interface 172.22.100.53
# curl -v http://10.10.10.1 --interface 172.22.100.54
# curl -v http://10.10.10.1 --interface 172.22.100.55
```
