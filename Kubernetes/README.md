
## Kubernetes install notes
Kubernetes installation support using application stack recommended by Red Hat.  

The Red Hat stack has been chosen primarily because it uses CRI-O as the container runtime and therefore bypasses most of the historical security issues.   

### Pre-install - VM Configuration

```
# ======== VM Configuration ========
hostname        IPa                  IPb
k-master    10.17.20.122          10.1.1.115
k-node01    10.17.20.123          10.1.1.116
k-node02    10.17.20.124          10.1.1.117

CPU   4
RAM   8 GB
HD    300 GB - eager thick

Perform minimal install on nodes.

Users: root, admin (with sudo added using visudo or steps below)
If admin user was not created during installation, add now using:
adduser admin
passwd admin
usermod -aG wheel admin
su - admin (Confirm sudo works)

# ==================================

Prior to running the installation script on the VMs noted above, 
make sure /etc/hosts has static IP entries on all VMs.
```

### Post install message from k-master

Your Kubernetes control-plane has initialized successfully!

__The k8s-install.sh script performs these steps__, however if you installed with an alternate method, to start using your cluster, on the master node you need to run the following as a regular user:   
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:   
export KUBECONFIG=/etc/kubernetes/admin.conf
```

__As above k8s-installs Calico__, if an alternative is desired:
```
You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/
```

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.17.20.115:6443 --token l7fgrv.k9vfhh46cwdp2be9 \
        --discovery-token-ca-cert-hash sha256:a2440cc5ca9262be6a5bf402f2e575616565e9f06833d6592b78a9553bd52d2f

### Adding worker nodes to cluster

This information is from [this link](https://computingforgeeks.com/join-new-kubernetes-worker-node-to-existing-cluster/)

__Jump ahead to Shortcut__

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

__Shortcut__
```
# Show the full command needed on the worker nodes, by entering on master:
kubeadm token create --print-join-command
```
Back on __master__, if no errors were displayed on the initializing node, you can watch its initialization using __kubectl get nodes__.

__Assigning ROLES Labels__
```
# General format:
# kubectl label nodes <my node name> kubernetes.io/role=<desired role label>
# Specific example:
kubectl label nodes k-node01 kubernetes.io/role=worker-01
```


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

### KIND Install notes 

Rootless mode errors:   
Error: rootlessport cannot expose privileged port 80, you can add 'net.ipv4.ip_unprivileged_port_start=80' to /etc/sysctl.conf (currently 1024), or choose a larger port (>= 1024).   

Set script config2.yaml to use containerPort: 80 & hostPort: 8080

**Post Install instructions...**   
```
# If running Docker, start the container engine using:
# sudo systemctl start docker
# systemctl status docker  << should show it is running
# NOTE - Although systemctl shows docker.service is running, no workie

# Set environment variables and aliases (as standard user)
echo 'alias docker=podman' >> ~/.bashrc 
echo export KIND_EXPERIMENTAL_PROVIDER=podman >> ~/.bashrc

echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc

```

**Installation tests...**   
```
kind create cluster      << After several minutes ...
kind get clusters        << Will show a cluster named 'kind'

# Exec into the Kind cluster
podman exec -it kind-control-plane bash

 Read available contexts
kubectl config get-contexts   << Should show info about the Kind cluster
 
# After poking around a bit, exit and delete 
kind delete cluster

# Testing more advanced clusters
kind create cluster --config config.yaml --name cfg1    << Wait for it, wait for it
kubectl get nodes

kind create cluster --config config2.yaml --name cka 
kubectl get nodes --show-labels && docker port cka-control-plane

kind delete cluster
```

**Setting context...**   
```
# Kind can read context of ~/.kube/config
kind get kubeconfig --name "myname"

# -- OR -- 
kubectl config view --minify

# See config of running cluster
kind create cluster --config config2.yaml 
kubectl get nodes
podman exec -it kind-control-plane bash
echo $KUBECONFIG

# KUBECONFIG can be modified to use multiple configurations
export KUBECONFIG=~/Downloads/config2:~/.kube/config

kubectl config get-contexts   << to list the defined configurations (active has *)
kubectl config use-context kind-kind
kubectl config get-contexts   << should show switch to different context
```

**Installing a CNI in a kind cluster...**   
```
# Create configuration to create cluster without CNI (no-cni.yaml)
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
nodes:
- role: control-plane
- role: worker

kind create cluster --image kindest/node:v1.25.0-beta.0 --config no-cni.yaml
# You will notice that it does not install CNI

# In separate shells, execute each node
podman exec -it kind-control-plane bash
podman exec -it kind-worker-plane bash

# Repeat these commands in each of the execute shells
apt update; apt install wget
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
tar -xvf cni-plugins-linux-amd64-v1.1.1.tgz

# Move the bridge file to the correct location
mv bridge /opt/cni/bin/

# Then, in the control plane shell
kubectl get nodes    << Will show NotReady
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml


kubectl get nodes    << After a minute will show Ready
kubectl get pods -A  << Will show kube-flannel pods are Running

# Installing Calico CNI
create cluster --image kindest/node:v1.25.0-beta.0 --config no-cni.yaml --name cka

```

**Post Install DNS Troubleshooting**   
```
# From Kubernetes Up & Running - Chapter 3 - Deploying a Kubernetes Cluster
# Cluster Compenents - Page 34

# Kubernetes Proxy
kubectl get daemonSets --namespace=kube-system kube-proxy    <= Success

# Kubernetes DNS
kubectl get deployments --namespace=kube-system core-dns     <= Fails
Error from server (NotFound): deployment.apps "core-dns" not found

kubectl get services --namespace=kube-system core-dns        <= Fails
Error from server (NotFound): deployment.apps "core-dns" not found



```

