#!/bin/bash

# Reference websites
# https://www.redhat.com/en/blog/introducing-cri-o-10
# https://access.redhat.com/containers/guide           << Openshift Introduction
# https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/cri-o_runtime/use-crio-engine#get-crio-use-crio-engine

# Following is from youtube video
# https://www.centlinux.com/2022/11/install-kubernetes-master-node-rocky-linux.html
#
# The following site provided information that allowed working around the version clashes with CRI-O & K8S
# https://hashnode.com/post/install-kubernetes-with-cri-o-container-runtime-on-centos-8-centos-7-cl0oz6cei04p12onv6dtofd3p
#
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



# #############################################################################
#
# POST Installation Instructions
#
# #############################################################################



# #############################################################################
#
function PerformUpdate
{
    echo "Function: PerformUpdate starting"

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
    echo "===================================================================="
    echo "Function: SetPermissiveMode Starting"
    echo "===================================================================="

    setenforce 0
    sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    echo "===================================================================="
    echo "Function: SetPermissiveMode Complete"
    echo "===================================================================="
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function ConfigureSysctl
{
    echo "===================================================================="
    echo "Function: ConfigureSysctl Starting"
    echo "===================================================================="

    # Not all examples include iproute-tc
    dnf -y install iproute-tc

    # Enable kernel modules (overlay & br_netfilter
    modprobe overlay
    modprobe br_netfilter

    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CONFIRM STEP: Check kernel module status                            "
    echo "# Output should show single line entry for overlay,                 "
    echo "#        and 2 line entry for br_netfilter                          "
    echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    lsmod | grep overlay
    lsmod | grep br_netfilter
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"  

    # Create config file to automatically load Kernel Modules
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
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CONFIRM STEP: sysctl --system                                       "
    echo "# Last line of output: Applying /etc/sysctl.conf                    "
    echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    sysctl --system
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

    echo "===================================================================="
    echo "Function: ConfigureSysctl complete"
    echo "===================================================================="
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function DisableSwap
{
    echo "===================================================================="
    echo "Function: DisableSwap Starting"
    echo "===================================================================="

    swapoff -a
    sed -e '/.* none.* swap.*/ s/^#*/#/' -i /etc/fstab

    # Check swap using /procs/swaps
    cat /proc/swaps

    # Check swap using free command
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CONFIRM STEP: DisableSwap                                           "
    echo "# Swap: line should show all zeros                                  "
    echo "# Should be no entries below Filename line                          "
    echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    free -m
    echo ""
    cat /proc/swaps
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

    echo "===================================================================="
    echo "Function: DisableSwap complete"
    echo "===================================================================="
}
# -----------------------------------------------------------------------------

# #############################################################################
# Supporting information from: https://computingforgeeks.com/install-cri-o-container-runtime-on-rocky-linux-almalinux/
# Alternate method from:
# https://hashnode.com/post/install-kubernetes-with-cri-o-container-runtime-on-centos-8-centos-7-cl0oz6cei04p12onv6dtofd3p
#
function InstallCRIO
{
    echo "===================================================================="
    echo "====== Function: InstallCRIO Starting         ======================"
    echo "===================================================================="

    # At time of this installation, 1.26 was not available in repos.
    # Therefore CRIO is one major revision behind k8s.
    export CRIO_VERSION=1.25
    export OS=CentOS_8

    # Define OS per installation instructions on https://cri-o.io
    # NOTE that the URLs provided seemed to have extraneous slashes that were breaking the download of the repos

    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo \
	https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/${OS}/devel:kubic:libcontainers:stable.repo

    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${CRIO_VERSION}.repo \
	https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${CRIO_VERSION}/${OS}/devel:kubic:libcontainers:stable:cri-o:${CRIO_VERSION}.repo

    dnf -y install cri-o cri-tools

    rpm --query cri-o

    # NOTE that the service name is crio, not cri-o
    systemctl enable --now crio
    systemctl start crio

    # To test operation, add admin account using visudo (if RH derivative)
    # sudo crictl pull hello-world:latest
    # sudo crictl pull alpine:latest
    # sudo crictl images   <== Should show both images pulled above

    echo "===================================================================="
    echo "Function: InstallCRIO complete"
    echo "===================================================================="
}
# -----------------------------------------------------------------------------

# #############################################################################
# TODO - Ports are believed to be correct, but may needs mods & optimizations
#
function ConfigureFirewall
{
    echo "===================================================================="
    echo "Function: ConfigureFirewall Starting"
    echo "===================================================================="

    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CONFIRM STEP: ConfigureFirewall"
    echo "# All steps should report 'success'"
    echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"

    # From 'Control Plane' list : https://kubernetes.io/docs/reference/ports-and-protocols/
    # TCP Inbound	2379-2380	etcd Server Cleint API	kube-apiserver, etcd
    # TCP Inbound	10250		Kubelet API		Self, Control Plane
    # TCP Inbound	10259		kube-scheduler		Self
    # TCP Inbound	10257		kube-controller-manager	Self

    # Master Node (Control Plane) ports
    firewall-cmd --zone=public --add-service=kube-apiserver --permanent    # Kubernetes API Server (port 6443)
    firewall-cmd --zone=public --add-service=etcd-client --permanent       # Kubernetes etcd Server API (port 2379)
    firewall-cmd --zone=public --add-service=etcd-server --permanent       # Kubernetes etcd Server API (port 2380)

    firewall-cmd --add-port=10250/tcp --permanent                          # Self, Control plane
    firewall-cmd --add-port={10251,10259}/tcp --permanent                  # Self, kube-scheduler
    firewall-cmd --add-port={10252,10257}/tcp --permanent                  # Self, kube-controller-manager

    # Duplicate of above ? etcd-client & etcd-server
    firewall-cmd --add-port={2379,2380}/tcp --permanent                    # kube-apiserver, etcd

    firewall-cmd --add-port=5473/tcp --permanent                           # ?

    firewall-cmd --add-port=4789/udp --permanent                           # ?
    firewall-cmd --add-port={8285,8472}/udp --permanent                    # ?

    # Ports for Calico CNI - needed for all nodes
    firewall-cmd --add-port=179/tcp --permanent                            # ?
    firewall-cmd --add-port=4789/tcp --permanent                           # ?

    firewall-cmd --add-masquerade --permanent                              # Associated with CRI-O ?

    # apply changes
    firewall-cmd --reload
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

    echo "===================================================================="
    echo "Function: ConfigureFirewall complete"
    echo "===================================================================="
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
    echo "===================================================================="
    echo "Function: InstallKubernetes Starting"
    echo "===================================================================="

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

    echo "===================================================================="
    echo "Installing Kubernetes Components"
    echo "===================================================================="
    dnf -y install kubelet kubeadm kubectl --disableexcludes=kubernetes

    echo "===================================================================="
    echo "kubeadm configuration (pull images)"
    echo "===================================================================="

    # Download container images required to create k8s cluster
    kubeadm config images pull

    # Optional items, as placeholders for now - enables bash completion in kubectl commands
    # source <(kubectl completion bash)
    # kubectl completion bash > /etc/bash_completion.d/kubectl

    echo "===================================================================="
    echo "Function: InstallKubernetes complete"
    echo "===================================================================="
}
# -----------------------------------------------------------------------------

# #############################################################################
# Use install information from https://projectcalico
# https://projectcalico.docs.tigera.io/getting-started/kubernetes/self-managed-onprem/onpremises#install-calico
#
function InstallCalico
{
    echo "===================================================================="
    echo "Function: InstallCalico Starting"
    echo "===================================================================="

    # Perform installation using the Operator method from the site noted above
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
    curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml -O

    kubectl create -f custom-resources.yaml

    # Install calicoctl
    pushd /usr/bin
    curl -L https://github.com/projectcalico/calico/releases/download/v3.25.0/calicoctl-linux-amd64 -o calicoctl
    chmod +x ./calicoctl
    popd

    # This should succeed, with the calico-* items showing STATUS = Pending
    kubectl get pods -n-kube-system

    echo "===================================================================="
    echo "Function: InstallCalico finished"
    echo "===================================================================="
}
# -----------------------------------------------------------------------------

# #############################################################################
#
# Cluster creation performed using kubeadm
#
function InitializeCluster
{
    echo "===================================================================="
    echo "Function InitializeCluster Starting"
    echo "===================================================================="

    # Initialize to use Classless Inter-Domain Routing (CIDR)
    kubeadm init --pod-network-cidr=192.168.0.0/16

    # Export KUBECONFIG - required for remaining configuration steps
    export KUBECONFIG=/etc/kubernetes/admin.conf

    # Setup permissions for admin user
    mkdir -p /home/admin/.kube
    cp -i /etc/kubernetes/admin.conf /home/admin/.kube/config
    chown -R admin:admin /home/admin/.kube/config

    echo "===================================================================="
    echo "Starting kubelet"
    echo "===================================================================="
    systemctl enable --now kubelet
    systemctl start kubelet

    # This should suceed, displaying k-master as the control-plane
    kubectl get nodes

    #And display custer information
    kubectl cluster-info

    echo "===================================================================="
    echo "kubeadm initialization finished"
    echo "===================================================================="
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
    echo "Function: InstallDashboard starting"

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

    echo "After running kubectl proxy"
    echo "Kubernetes Dashboard will be available:"
    echo "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"

    echo "Function: InstallDashboard complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function ShowServerSpecifications
{
    echo "####################################################################"
    echo "Basic specifications of this machine:"
    echo "Memory:"
    free -h

    echo "Disk space:"
    df -hT

    echo "CPU Cores:"
    egrep ^processor /proc/cpuinfo | wc -l

    echo "####################################################################"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function Spare_Function
{
    echo "Function: Spare_Function starting"

    echo "Function: Spare_Function complete"
}
# -----------------------------------------------------------------------------


# =============================================================================
# =============================================================================
# Script execution starts below
# =============================================================================
# =============================================================================

echo "Applying MASTER Node settings to installation"

PerformUpdate     # Some references recommend reboot after this step

SetPermissiveMode # Disables SELinux
DisableSwap       #

ConfigureSysctl
ConfigureFirewall

InstallCRIO     # << Needed by kubeadm
InstallKubernetes
InitializeCluster
InstallCalico

#InstallDashboard
#ShowServerSpecifications

