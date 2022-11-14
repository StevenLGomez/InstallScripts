#!/bin/bash

# Reference websites
# https://www.redhat.com/en/blog/introducing-cri-o-10
# https://access.redhat.com/containers/guide           << Openshift Introduction
# https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/cri-o_runtime/use-crio-engine#get-crio-use-crio-engine
#
# The following site provided information that allowed working around the version clashes with CRI-O & K8S
#
# https://hashnode.com/post/install-kubernetes-with-cri-o-container-runtime-on-centos-8-centos-7-cl0oz6cei04p12onv6dtofd3p
#
# First pass of VMs created as:
#
# k-master
# k-node01
# k-node02
#
# CPU   4
# RAM   8 GB
# HD    300 GB thin


# #############################################################################
#
# POST Installation Instructions
#
# #############################################################################
# To start using your cluster, you need to run the following as a regular user:
# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config
#
# You should now deploy a pod network to the cluster.
# run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#    https://kubernetes.io/docs/concepts/cluster-administration/addons/

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
CRIO_VERSION=1.25
K8S_VERSION=v1.25


# #############################################################################
#
function PerformUpdate
{
    echo "Function: PerformUpdate starting (STEP 0)"

    dnf -y update

    # Install basic applications
    dnf -y install vim git wget curl

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

    # Check swap using /procs/swaps
    cat /proc/swaps

    # Check swap using free command
    free -m

    echo "Function: DisableSwap complete (STEP 1)"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function SetupKernelModules
{
    echo "Function: SetupKernelModules starting"

    # Not all examples include iproute-tc
    dnf -y install iproute-tc

    # Create config file to Automatically load Kernel Modules
cat <<EOF | sudo tee /etc/modules-load.d/kubernetes.conf
overlay
br_netfilter
EOF

    # Enable kernel modules (overlay & br_netfilter
    modprobe overlay
    modprobe br_netfilter

    # Check kernel module status
    # Output should show single line entry for overlay,
    #        and 2 line entry for br_netfilter
    lsmod | grep overlay
    lsmod | grep br_netfilter

    # Create config file to enable Bridge Networking (net.bridge)
# setting up kernel parameters via config file
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

    # Apply new kernel parameters
    sysctl --system

    echo "Function: SetupKernelModules complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
# TODO Ports are believed to be correct, but may needs mods & optimizations
#
function ConfigureFirewall
{
    echo "Function: ConfigureFirewall starting (STEP 3)"

    if [ $NODE_TYPE = "MASTER" ]
    then
	echo "Applying MASTER Node firewall settings"

	# From 'Control Plane' list : https://kubernetes.io/docs/reference/ports-and-protocols/
	# TCP Inbound	2379-2380	etcd Server Cleint API	kube-apiserver, etcd
	# TCP Inbound	10250		Kubelet API		Self, Control Plane
	# TCP Inbound	10259		kube-scheduler		Self
	# TCP Inbound	10257		kube-controller-manager	Self

	# I suspect there were be duplications below....

	firewall-cmd --zone=public --add-service=kube-apiserver --permanent    # Kubernetes API Server (port 6443)
	firewall-cmd --zone=public --add-service=etcd-client --permanent       # Kubernetes etcd Server API (port 2379)
	firewall-cmd --zone=public --add-service=etcd-server --permanent       # Kubernetes etcd Server API (port 2379)

	# Master Node (Control Plane) ports
	firewall-cmd --add-port={6443,2380,10250,10251,10252,5473}/tcp --permanent

	# Ports for Calico CNI
	firewall-cmd --add-port=179/tcp --permanent
	firewall-cmd --add-port=2379/tcp --permanent
	firewall-cmd --add-port=4789/tcp --permanent

	firewall-cmd --add-port=4789/udp --permanent
	firewall-cmd --add-port={8285,8472}/udp --permanent

    fi

    if [ $NODE_TYPE = "WORKER" ]
    then
	echo "Applying WORKER Node firewall settings"

	# From 'Worker Node' list : https://kubernetes.io/docs/reference/ports-and-protocols/
	# TCP Inbound	10250		Kubelet API		Self, Control Plane
	# TCP Inbound	30000-32767	NodePort Services	All

	firewall-cmd --add-port={10250,30000-32767,5473,5473}/tcp --permanent
	firewall-cmd --add-port={4789,8285,8472}/udp --permanent

    fi

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
# Alternate method from:
# https://hashnode.com/post/install-kubernetes-with-cri-o-container-runtime-on-centos-8-centos-7-cl0oz6cei04p12onv6dtofd3p
#
# To test operation, add admin account using visudo (if RH derivative)
# sudo crictl pull hello-world:latest
# sudo crictl pull alpine:latest
# sudo crictl images   <== Should show both images pulled above
#
function InstallCRIO
{
    echo "Function: InstallCRIO starting (STEP 5)"

    dnf -y install 'dnf-command(copr)'
    dnf -y copr enable rhcontainerbot/container-selinux

    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo \
	https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_8/devel:kubic:libcontainers:stable.repo

    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${CRIO_VERSION}.repo \
	https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${CRIO_VERSION}/CentOS_8/devel:kubic:libcontainers:stable:cri-o:${CRIO_VERSION}.repo

    dnf -y install cri-o cri-tools

    rpm -qi cri-o

    systemctl daemon-reload

    # NOTE that the service is crio, not cri-o
    systemctl enable --now crio
    systemctl start crio

    echo "Function: InstallCRIO complete (STEP 5)"
}
# -----------------------------------------------------------------------------


# #############################################################################
# https://v1-21.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# New info follows:
# https://hashnode.com/post/install-kubernetes-with-cri-o-container-runtime-on-centos-8-centos-7-cl0oz6cei04p12onv6dtofd3p
#
# And directly from Kubernetes documentation:
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
#
#
function InstallKubernetes
{
    echo "Function: InstallKubernetes starting (STEP 6), alternate method"

    # Note - HERE Docs must be on column zero.

tee /etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

    # Perform another update to pull information from the repository above
    dnf -y update

    # Install the necessary packages - Removed duplicates
    # dnf -y install epel-release vim git curl wget kubelet kubeadm kubectl --disableexcludes=kubernetes
    dnf -y install kubelet kubeadm kubectl --disableexcludes=kubernetes

    echo "=============================================================================================="
    echo "======================== Kubernetes Component Installation Complete =========================="
    echo "=============================================================================================="

    # Do some kubeadm configurations
    echo "Pulling images..."
    kubeadm config images pull

    echo "kubeadm initializing..."
    # kubeadm init --pod-network-cidr=10.17.20.112/29 --cri-socket /var/run/crio/crio.sock
    kubeadm init --cri-socket /var/run/crio/crio.sock

    echo "=============================================================================================="
    echo "======================== Starting kubelet ===================================================="
    echo "=============================================================================================="

    # Enable kubelet service
    systemctl enable --now kubelet
    systemctl start kubelet

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
#
# See information from: https://adamtheautomator.com/cri-o/
#
function DeployCalicoNetworking
{
    echo "Function: DeployCalicoNetworking starting (STEP 7)"


    echo "Function: DeployCalicoNetworking complete (STEP 7)"

}
# -----------------------------------------------------------------------------


# #############################################################################
# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
#
# https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
# Web UI will be available:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/.
#
# after: kubectl proxy &
#
function InstallDashboard
{
    echo "Function: InstallDashboard starting (STEP 8)"

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml

    echo "After running kubectl proxy"
    echo "Kubernetes Dashboard will be available:"
    echo "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"


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
    egrep ^processor /proc/cpuinfo | wc -l

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

# Require one parameter
# $1 = Option String
#
# Supported options defined in if statement below
#

if [ -z "$1" ]
then
    echo "ERROR: Missing parameter - must specify MASTER or WORKER node"
    echo ""
    echo "Supported Options:"
    echo "    MASTER    Performs installation using settings for Master node"
    echo "    WORKER    Performs installation using settings for Worker node"
    echo ""
    echo "Usage: $0 MASTER || WORKER"
    exit
fi

# Echo the valid command line entry
echo $0 $1

if [ "$1" = "MASTER" ]
then
    echo "Applying MASTER Node settings to installation"
    NODE_TYPE="MASTER"
fi

if [ "$1" = "WORKER" ]
then
    echo "Applying WORKER Node settings to installation"
    NODE_TYPE=WORKER
fi

echo "Applying NODE_TYPE:  ${NODE_TYPE}"

#  Start the installation procedure....

PerformUpdate

SetupKernelModules
DisableSwap
DisableSELinux
ConfigureFirewall
InstallCRIO
InstallKubernetes

exit

DeployCalicoNetworking

CreateCluster

InstallDashboard
ShowServerSpecifications

