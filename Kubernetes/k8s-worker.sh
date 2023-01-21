#!/bin/bash

# Reference websites
# https://www.redhat.com/en/blog/introducing-cri-o-10
# https://access.redhat.com/containers/guide           << Openshift Introduction
# https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/cri-o_runtime/use-crio-engine#get-crio-use-crio-engine

# Following is from youtube video
# https://www.centlinux.com/2022/11/install-kubernetes-master-node-rocky-linux.html

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
CRIO_VERSION=1.25 # <<==  At time of this installation, 1.26 was not available in repos
# not used K8S_VERSION=v1.25


# #############################################################################
#
function PerformUpdate
{
    echo "Function: PerformUpdate starting (STEP 0)"

    dnf makecache --refresh
    dnf -y update

    # Install basic applications
    dnf -y install vim git wget curl

    echo "Function: PerformUpdate complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function SetPermissiveMode
{
    echo "=============================================================================================="
    echo "======================== Function: SetPermissiveMode Starting ================================"
    echo "=============================================================================================="

    setenforce 0
    sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    echo "=============================================================================================="
    echo "======================== Function: SetPermissiveMode Complete ================================"
    echo "=============================================================================================="
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function ConfigureSysctl
{
    echo "=============================================================================================="
    echo "======================== Function: ConfigureSysctl Starting   ================================"
    echo "=============================================================================================="

    # Not all examples include iproute-tc
    dnf -y install iproute-tc

    # Enable kernel modules (overlay & br_netfilter
    modprobe overlay
    modprobe br_netfilter

    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CONFIRM STEP: Check kernel module status                                                      "
    echo "# Output should show single line entry for overlay,                                           "
    echo "#        and 2 line entry for br_netfilter                                                    "
    echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    lsmod | grep overlay
    lsmod | grep br_netfilter
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

    # Create config file to Automatically load Kernel Modules
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

    # Create config file to enable Bridge Networking (net.bridge)
# setting up kernel parameters via config file
cat > /etc/sysctl.d/k8s.conf <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

    # Apply new kernel parameters
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CONFIRM STEP: sysctl --system                                                                 "
    echo "# Last line of output: Applying /etc/sysctl.conf                                             "
    echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    sysctl --system
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

    echo "=============================================================================================="
    echo "======================== Function: ConfigureSysctl complete   ================================"
    echo "=============================================================================================="
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
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CONFIRM STEP: DisableSwap                                                                     "
    echo "# Swap: line should show all zeros                                                           "
    echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    free -m
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

    echo "Function: DisableSwap complete (STEP 1)"
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
    echo "=============================================================================================="
    echo "======================== Function: InstallCRIO Starting         =============================="
    echo "=============================================================================================="

    # Define OS per installation instructions on https://cri-o.io
    # NOTE that the URLs provided seemed to have extraneous slashes that were breaking the download of the repos
    export OS=CentOS_8

    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo \
	https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/${OS}/devel:kubic:libcontainers:stable.repo

    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${CRIO_VERSION}.repo \
	https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${CRIO_VERSION}/${OS}/devel:kubic:libcontainers:stable:cri-o:${CRIO_VERSION}.repo

    dnf -y install cri-o cri-tools

    rpm --query cri-o

    # NOTE that the service name is crio, not cri-o
    systemctl enable --now crio
    systemctl start crio

    echo "=============================================================================================="
    echo "======================== Function: InstallCRIO complete         =============================="
    echo "=============================================================================================="
}
# -----------------------------------------------------------------------------

# #############################################################################
# TODO - Ports are believed to be correct, but may needs mods & optimizations
#
function ConfigureFirewall
{
    echo "=============================================================================================="
    echo "======================== Function: ConfigureFirewall Starting   =============================="
    echo "=============================================================================================="

    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CONFIRM STEP: ConfigureFirewall                                                               "
    echo "# All steps should report 'success'                                                           "
    echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    # From 'Worker Node' list : https://kubernetes.io/docs/reference/ports-and-protocols/
    # TCP Inbound	10250		Kubelet API		Self, Control Plane
    # TCP Inbound	30000-32767	NodePort Services	All

    firewall-cmd --add-port={10250,30000-32767,5473,5473}/tcp --permanent
    firewall-cmd --add-port={4789,8285,8472}/udp --permanent

    # Ports for Calico CNI - needed for all nodes
    firewall-cmd --add-port=179/tcp --permanent
    firewall-cmd --add-port=2379/tcp --permanent
    firewall-cmd --add-port=4789/tcp --permanent

    # apply changes
    firewall-cmd --reload
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

    echo "=============================================================================================="
    echo "======================== Function: ConfigureFirewall complete   =============================="
    echo "=============================================================================================="
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
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
#
function InstallKubernetes
{
    echo "Function: InstallKubernetes starting (STEP 6), alternate method"

    # Note - HERE Docs must be on column zero.

cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

    echo "=============================================================================================="
    echo "======================== Installing Kubernetes Components ===================================="
    echo "=============================================================================================="
    dnf -y install kubelet kubeadm kubectl --disableexcludes=kubernetes

    echo "=============================================================================================="
    echo "======================== kubeadm configuration (pull images) ================================="
    echo "=============================================================================================="

    # Download container images required to create k8s cluster
    kubeadm config images pull

    # Optional items, as placeholders for now - enables bash completion in kubectl commands
    # source <(kubectl completion bash)
    # kubectl completion bash > /etc/bash_completion.d/kubectl

    echo "Function: InstallKubernetes complete (STEP 6)"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
# See information from: https://adamtheautomator.com/cri-o/
#
# https://www.golinuxcloud.com/calico-kubernetes/
# https://www.golinuxcloud.com/deploy-multi-node-k8s-cluster-rocky-linux-8/#Step_1_Prepare_the_Kubernetes_Cluster
#
# https://github.com/cri-o/cri-o/blob/main/install.md#other-yum-based-operating-systems
#
function InstallCalico
{
    echo "Function: InstallCalico starting (STEP 7)"

    # Download calico.yaml - can optionally edit it here as well before applying
    curl https://docs.projectcalico.org/manifests/calico.yaml -O

    kubectl apply -f calico.yaml

    # This should succeed, with the calico-* items showing STATUS = Pending
    kubectl get pods -n-kube-system

    echo "Function: InstallCalico complete (STEP 7)"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
# Cluster creation performed using kubeadm
#
function InitializeCluster
{
    echo "Function: InitializeCluster starting (STEP 7)"

    echo "=============================================================================================="
    echo "======================== kubeadm initialization starting ====================================="
    echo "=============================================================================================="

    # Initialize to use Classless Inter-Domain Routing (CIDR)
    kubeadm init --pod-network-cidr=192.168.0.0/16

    echo "=============================================================================================="
    echo "======================== Starting kubelet ===================================================="
    echo "=============================================================================================="

    # Enable kubelet service
    systemctl enable --now kubelet
    systemctl start kubelet
    #systemctl status kubelet  # <== Can be used to check status, but hangs script (must enter q to continue)

#    if [ $NODE_TYPE = "MASTER" ]
#    then
#
#	# Set KUBECONFIG variable for all sessions
#	echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/profile.d/k8s.sh
#
#        # Setup permissions for admin user
#        mkdir -p /home/admin/.kube
#        cp -i /etc/kubernetes/admin.conf /home/admin/.kube/config
#        chown -R admin:admin /home/admin/.kube/config
#
#        # This should suceed, displaying k-master as the control-plane
#        kubectl get nodes
#
#	# And display custer information
#	kubectl cluster-info
#    fi

    echo "Function: InitializeCluster complete (STEP 7)"
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

echo "Applying WORKER Node settings to installation"

#  Start the installation procedure....

PerformUpdate   # Some references recommend reboot after this step

SetPermissiveMode # Disables SELinux
DisableSwap

ConfigureSysctl

ConfigureFirewall
InstallCRIO

exit

InstallKubernetes

# Master AND Worker nodes REQUIRE Calico Networking - kubectl is used for configuration
InstallCalico

InitializeCluster

#InstallDashboard # Master only

ShowServerSpecifications

