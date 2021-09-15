#!/bin/bash

# Installation of Podman/Docker on Kubernetes cluster
#
# Post installation steps:
#
# On Master node (as root ?):
# kubeadm init
#
# Then as standard user:   (instructions output by running 'kubeadm init')
# sudo cp /etc/kubernetes/admin.conf $HOME/
# sudo chown $(id -u):$id -g) $HOME/admin.conf
# export KUBECONFIG=$HOME/admin.conf
#
# Deploy a pod network to the cluster.
# kubectl apply -f [podnetwork].yaml (with one of the options listed at http://kubernetes.io/docs/admin/addons/)
#
# Join any number of machines by running the following on each node as root:
# kubeadm join --token <token> <master-ip>:<master-port>
#
# Make a record of the kubeadm_join command output.  It is needed later.





# ====================================================================================
# Normal update...
function PerformUpdate
{
    dnf -y update
}
# ------------------------------------------------------------------------


# ====================================================================================
#
function ConfigureFirewall
{
    firewall-cmd --permanent --add-port=6443/tcp
    firewall-cmd --permanent --add-port=2379-2380/tcp
    firewall-cmd --permanent --add-port=10250/tcp
    firewall-cmd --permanent --add-port=10251/tcp
    firewall-cmd --permanent --add-port=10252/tcp
    firewall-cmd --permanent --add-port=10255/tcp
    firewall-cmd --permanent --add-port=30000-32767/tcp
    firewall-cmd --zone=trusted --permanent --add-source 10.1.0.0/24
    firewall-cmd --add-masquerade --permanent

    modprobe br_netfilter
    systemctl restart firewalld
}
# ------------------------------------------------------------------------

# ====================================================================================
#
function SetHostNames
{
    if grep -q k-master /etc/hosts; then
	echo "k-master entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding k-master to /etc/hosts (Kubernetes Master)"
	echo '10.1.1.200   k-master  k-master.gomezengineering.lan    # Kubernetes Master' >> /etc/hosts
    fi

    if grep -q k-node-1 /etc/hosts; then
	echo "k-node-1 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding k-node-1 to /etc/hosts (Kubernetes Master)"
	echo '10.1.1.201   k-node-1  k-node-1.gomezengineering.lan    # Kubernetes Worker Node 1' >> /etc/hosts
    fi

    if grep -q k-node-2 /etc/hosts; then
	echo "k-node-2 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding k-node-2 to /etc/hosts (Kubernetes Master)"
	echo '10.1.1.202   k-node-2  k-node-2.gomezengineering.lan    # Kubernetes Worker Node 2' >> /etc/hosts
    fi
}
# ------------------------------------------------------------------------

# ====================================================================================
# NOTE that RHEL uses the open source replicant of Docker (podman Pod Manager)
#      The install steps here are from:
#      https://podman.io/getting-started/installation
#
function InstallPodman
{
    # The following is from the Red Hat reference noted above:
    yum module install -y container-tools
    yum install -y podman-docker
    
    # Set up rootless container access
    yum install -y slirp4netns podman
    echo "user.max_user_namespaces=28644" > /etc/sysctl.d/userns.conf
    sysctl -p /etc/sysctl.d/userns.conf
}
# ------------------------------------------------------------------------

# ====================================================================================
#
function InstallDocker

    # Install and start Docker
    dnf -y install docker
    systemctl enable docker && systemctl start docker
# ------------------------------------------------------------------------

# ====================================================================================
# From: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/ (for repository file contents)
#       https://unofficial-kubernetes.readthedocs.io/en/latest/getting-started-guides/kubeadm/ (for kubeadm steps)
#
function InstallKubernetes

# Create yum repository file - NOTE: must begin at column 1
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

    # It is known that kube* currently don't play well with SELinux, so disable SELinux
    setenforce 0

    # Install Kubernetes pieces, then start it
    yum install -y kubelet kubeadm kubectl kubernetes-cni
    systemctl enable kubelet && systemctl start kubelet

    # "It needs a kubeconfig file" which is created when you create a cluster using kube-up.sh.
    # See ~/.kube/config

    # Check operation & configuration
    kubectl cluster-info

#    TBD .....
#    systemctl enable --now kubelet

#    systemctl status kubelet
#    vi /etc/sysconfig/kubelet 
#    systemctl stop kubelet
#    systemctl status kubelet

#    swapoff -a
#    vi /etc/fstab

# ------------------------------------------------------------------------


PerformUpdate
ConfigureFirewall
SetHostNames
# InstallPodman
InstallDocker

# InstallKubernetes

