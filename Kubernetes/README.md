
## Kubernetes install notes
Kubernetes installation support using application stack recommended by Red Hat.  

The Red Hat stack has been chosen primarily because it uses CRI-O as the container runtime and therefore bypasses most of the historical security issues.   

### Pre-install - VM Configuration

```
# ======== VM Configuration ========
hostname        IPa                  IPb
k-master    10.17.20.122          10.1.1.115
k-node01    10.17.20.122          10.1.1.116
k-node02    10.17.20.122          10.1.1.117

CPU   4
RAM   8 GB
HD    300 GB - eager thick

Perform minimal install on nodes.
Users: root, admin (with sudo added using visudo)
# ==================================

Prior to running the installation script on the VMs noted above, 
make sure /etc/hosts has static IP entries on all VMs.
```

### Post install message from k-master

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, on the master node you need to run the following as a regular user:   
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Alternatively, if you are the root user, you can run:   
```
export KUBECONFIG=/etc/kubernetes/admin.conf
```

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.17.20.115:6443 --token l7fgrv.k9vfhh46cwdp2be9 \
        --discovery-token-ca-cert-hash sha256:a2440cc5ca9262be6a5bf402f2e575616565e9f06833d6592b78a9553bd52d2f

### Adding worker nodes to cluster

This information is from [this link](https://computingforgeeks.com/join-new-kubernetes-worker-node-to-existing-cluster/)

__On master__, get token using \(as non root user\) __kubeadm token list__
If the token has expired, generate a new one using __sudo kubeadm token create__
Display the current token using:
```
kubeadm token list
```   
Read the Discovery Token certificate hash using:
```
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```   
Read the API Server \(Master\'s\) advertise address using:
```
kubectl cluster-info
```

__On the new node__ use __kubeadm join [api-server-endpoint] [flags]__ as follows:
```
kubeadm join \
  <control-plane-host>:<control-plane-port> \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```   
Will be similar to:
```
kubeadm join 10.17.20.115:6443 \
	--token jyi49d.m760h13um8trogbs \
	--discovery-token-ca-cert-hash sha256:51fb0f2f89b20791cb19341ea33c255b70dc5a5fb8ed235b24eb8028fbc0efce
```

The command output from above should show __preflight__ and __kubelet_start__ information.

Back on __master__, if no errors were displayed on the initializing node, you can watch its initialization using __kubectl get nodes__.

### Helpful addons

Since the YAML syntax can be pretty persnickity, you might want to install yamllint using __python3 -m pip install --user yamllint__

See documentation [here](https://www.redhat.com/sysadmin/check-yaml-yamllint).   
There is also an online version [here](https://www.yamllint.com).   

### Removing worker nodes from cluster - USE WITH EXTREME CAUTION

First drain any active pods from the worker node (I think this is all done on the control plane)
```
kubectl drain <node-name> --delete-emptydir-data --ignore-daemonsets
```
Prevent a node from starrting new pods \(mark as unschedulable\).
```
kubectl cordon <node-name>
```

Then on the working node being removed, revert the previous join changes using:
```
sudo kubeadm reset
```

