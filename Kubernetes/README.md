
## Kubernetes install notes

### Pre-install - VM Configuration

```
# ======== VM Configuration ========
#
# k-master
# k-node01
# k-node02
#
# CPU   4
# RAM   8 GB
# HD    300 GB thin
# ==================================

All nodes must have sudo permission applied to a non-root user account (using visudo)
```

### Post install message from k-master


Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

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
Display the current token using __kubeadm token list__
Read the Discovery Token certificate hash using
__openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'__
Read the API Server \(Master's\) advertise address using __kubectl cluster-info__

__On the new node__ use __kubeadm join {api-server-endpoint] [flags]__ as follows:
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

See documentation [here](https://www.redhat.com/sysadmin/check-yaml-yamllint)
There is also an online version [here](https://www.yamllint.com)


### Removing worker nodes from cluster - USE WITH EXTREME CAUTION

First drain any active pods from the worker node (I think this is all done on the control plane)

__kubectl drain <node-name> --delete-emptydir-data --ignore-daemonsets__

Prevent a node from starrting new pods - mark as unschedulable

__kubectl cordon <node-name>__

Then on the working node being removed, revert the previous join changes using __sudo kubeadm reset__.


