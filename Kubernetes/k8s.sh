#!/bin/bash

# Reference websites
# https://www.redhat.com/en/blog/introducing-cri-o-10
# https://access.redhat.com/containers/guide           << Openshift Introduction
# https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/cri-o_runtime/use-crio-engine#get-crio-use-crio-engine
# First pass of VMs created as:
# CPU   4
# RAM   8 GB
# HD    300 GB thin

# Component versions defined here:
# https://graspingtech.com/install-kubernetes-rhel-8/
# Kubernetes v1.21.2
# CRI-O v1.21.1
# Calico

# Per Red Hat Support information, https://access.redhat.com/solutions/4870701
# OpenShift 4.11 uses these versions (as of October 3, 2022):
#CRIO_VERSION=1.24
#K8S_VERSION=v1.24

# But the versions noted above do not install properly on RHEL 8, so revert to these:
CRIO_VERSION=1.21.1
K8S_VERSION=v1.21.2


# #############################################################################
#
function PerformUpdate
{
    echo "Function: PerformUpdate starting (STEP 0)"
    dnf -y update
    echo "Function: PerformUpdate complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function DisableSwap
{
    echo "Function: DisableSwap starting (STEP 1)"
    swapoff -a
    sed -e '/.* none.* swap.*/ s/^#*/#/' -i /etc/fstab
    echo "Function: DisableSwap complete (STEP 1)"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function ConfigureNetwork
{
    echo "Function: ConfigureNetwork starting (STEP 2)"

    # Update /etc/hosts

    # GESLLC updates
#    if grep -q rk-master /etc/hosts; then
#    echo "rk-master entry already exists in /etc/hosts (skipping)"
#    else
#	echo "Adding rk-master to /etc/hosts (ESXi Server)"
#	echo '10.1.1.115     rk-master  rk-master.gomezengineering.lan    # Kubernetes Master' >> /etc/hosts
#    fi
#
#    if grep -q rk-node01 /etc/hosts; then
#    echo "rk-node01 entry already exists in /etc/hosts (skipping)"
#    else
#	echo "Adding rk-node01 to /etc/hosts (ESXi Server)"
#	echo '10.1.1.116     rk-node01  rk-node01.gomezengineering.lan    # Kubernetes Worker 01' >> /etc/hosts
#    fi
#
#    if grep -q rk-node02 /etc/hosts; then
#    echo "rk-node02 entry already exists in /etc/hosts (skipping)"
#    else
#	echo "Adding rk-node02 to /etc/hosts (ESXi Server)"
#	echo '10.1.1.117     rk-node02  rk-node02.gomezengineering.lan    # Kubernetes Worker 02' >> /etc/hosts
#    fi

    # vCenter updates
    if grep -q k-master /etc/hosts; then
    echo "k-master entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding k-master to /etc/hosts (ESXi Server)"
	echo '10.17.20.115     k-master  k-master.corp.internal    # Kubernetes Master' >> /etc/hosts
    fi

    if grep -q k-node01 /etc/hosts; then
    echo "k-node01 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding k-node01 to /etc/hosts (ESXi Server)"
	echo '10.17.20.116     k-node01  k-node01.corp.internal    # Kubernetes Worker 01' >> /etc/hosts
    fi

    if grep -q k-node02 /etc/hosts; then
    echo "k-node02 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding k-node02 to /etc/hosts (ESXi Server)"
	echo '10.17.20.117     k-node02  k-node02.corp.internal    # Kubernetes Worker 02' >> /etc/hosts
    fi

    dnf -y install iproute-tc

    # Configure iptables to see bridged traffic
    # Create the .conf file to load the modules at bootup
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    modprobe overlay
    modprobe br_netfilter

    # Set up required sysctl params, these persist across reboots.
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

    sysctl --system

    echo "Function: ConfigureNetwork complete (STEP 2)"
}
# -----------------------------------------------------------------------------

# #############################################################################
# TODO Ports are believed to be correct, but may needs mods & optimizations
#
function ConfigureFirewall
{
    echo "Function: ConfigureFirewall starting (STEP 3)"

    # Master Node (Control Plane) ports
    firewall-cmd --zone=public --add-service=kube-apiserver --permanent    # Kubernetes API Server (port 6443)
    firewall-cmd --zone=public --add-service=etcd-client --permanent       # Kubernetes etcd Server API (port 2379)
    firewall-cmd --zone=public --add-service=etcd-server --permanent       # Kubernetes etcd Server API (port 2379)

    firewall-cmd --zone=public --add-port=10251/tcp --permanent            # kube-scheduler
    firewall-cmd --zone=public --add-port=10252/tcp --permanent            # kube-controller-manager

    # Needed by Master & Worker Nodes
    firewall-cmd --zone=public --add-port=10250/tcp --permanent            # kubelet API

    # Worker Nodes only
    firewall-cmd --zone=public --add-port=30000-32767/tcp --permanent      # NodePort Services

    # apply changes
    firewall-cmd --reload

    echo "Function: ConfigureFirewall complete (STEP 3)"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function DisableSELinux
{
    echo "Function: DisableSELinux starting (STEP 4)"

    setenforce 0
    sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    echo "Function: DisableSELinux complete (STEP 4)"
}
# -----------------------------------------------------------------------------

# #############################################################################
# Supporting information from: https://computingforgeeks.com/install-cri-o-container-runtime-on-rocky-linux-almalinux/
#
# To test operation, add admin account using visudo (if RH derivative)
# sudo crictl pull hello-world:latest
# sudo crictl pull alpine:latest
# sudo crictl images   <== Should show both images pulled above
#
function InstallCRI-O
{
    echo "Function: InstallCRI-O starting (STEP 5)"

    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo \
	https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo
    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.repo \
	https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/CentOS_8/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.repo

    dnf install -y cri-o

    dnf install -y cri-tools  # This is optional, but allows testing CRI-O prior to installing Kubernetes

    systemctl enable --now cri-o
    systemctl start cri-o

    echo "Function: InstallCRI-O complete (STEP 5)"
}
# -----------------------------------------------------------------------------

# #############################################################################
# https://v1-21.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
#
function InstallKubernetes
{
    echo "Function: InstallKubernetes starting (STEP 6)"

    # Using Package Management (Note - doesn't work on Rocky)
#cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
#[kubernetes]
#name=Kubernetes
#baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
#enabled=1
#gpgcheck=1
#repo_gpgcheck=1
#gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
#exclude=kubelet kubeadm kubectl
#EOF

#yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    # =====================================================================

    # Alternate using CURL Kubernetes v1.21.2
    # For latest release: curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    #                     curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

    # kubectl
    curl -LO https://dl.k8s.io/release/$K8S_VERSION/bin/linux/amd64/kubectl
    curl -LO "https://dl.k8s.io/$K8S_VERSION/bin/linux/amd64/kubectl.sha256"
    echo "$(<kubectl.sha256) kubectl" | sha256sum --check   # Confirms sha, should show OK
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # kubeadm
    curl -LO https://dl.k8s.io/release/$K8S_VERSION/bin/linux/amd64/kubeadm
    curl -LO "https://dl.k8s.io/$K8S_VERSION/bin/linux/amd64/kubeadm.sha256"
    echo "$(<kubeadm.sha256) kubeadm" | sha256sum --check   # Confirms sha, should show OK
    install -o root -g root -m 0755 kubeadm /usr/local/bin/kubeadm

    # kubelet
    curl -LO https://dl.k8s.io/release/$K8S_VERSION/bin/linux/amd64/kubelet
    curl -LO "https://dl.k8s.io/$K8S_VERSION/bin/linux/amd64/kubelet.sha256"
    echo "$(<kubelet.sha256) kubelet" | sha256sum --check   # Confirms sha, should show OK
    install -o root -g root -m 0755 kubelet /usr/local/bin/kubelet

    # Create HERE Doc for kubelet.service
cat <<EOF | tee /etc/systemd/system/kubelet.service
# Contents lifted from RHEL 8 installation
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
# ExecStart=/usr/bin/kubelet # RHEL 8 Location (From repository method)
ExecStart=/usr/local/bin/kubelet # Rocky 8 Location (From curl method)
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Enable & start kubelet service
    systemctl enable --now kubelet
    systemctl start kubelet

    # To troubleshoot kubelet issues
    # journalctl -xeu kubelet

    echo "Function: InstallKubernetes complete (STEP 6)"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function CreateCluster
{
    echo "Function: CreateCluster starting (STEP 7)"

    kubeadm init --pod-network-cidr=10.1.1.115/20 --ignore-preflight-errors=FileExisting-conntrack

    echo "Function: CreateCluster complete (STEP 7)"
}
# -----------------------------------------------------------------------------

# #############################################################################
# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
#
function InstallDashboard
{
    echo "Function: InstallDashboard starting (STEP 8)"

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml

    echo "Function: InstallDashboard complete (STEP 8)"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function ShowServerSpecifications
{
    echo "#############################################################################"
    echo "Basic specifications of this machine:"
    echo "Memory:"
    free -h

    echo "Disk space:"
    df -hT

    echo "CPU Cores:"
    egrep ^processor /proc/cpuinto | wc -l

    echo "#############################################################################"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function Spare_Function
{
    echo "Function: ZOT starting (STEP 1)"

    echo "Function: ZOT complete (STEP 1)"
}
# -----------------------------------------------------------------------------


# =============================================================================
# =============================================================================
# Script execution starts below
# =============================================================================
# =============================================================================

PerformUpdate

DisableSwap
ConfigureNetwork
ConfigureFirewall
DisableSELinux
InstallCRI-O
InstallKubernetes
CreateCluster
InstallDashboard

ShowServerSpecifications



