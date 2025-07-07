# As root

####################################################
# Docker installation
# From: Docker Up and Running PDF
# Note that this book uses CentOS 7 (CentOS 8 was not yet available)
#      and CentOS 8 specific yum repos are not yet available either
#      at the time of this writing - 20191017
#
#      Made updates 20200527 based on changes posted https://docs/docker.com
#
####################################################
function InstallDocker
{
    # https://www.techrepublic.com/article/a-better-way-to-install-docker-on-centos-8/
    # The link above shows workaround for mismatch encountered with containerd.io
    #
    # See also:
    # https://thenewstack.io/how-to-install-a-kubernetes-cluster-on-red-hat-centos-8/

    dnf -y erase docker*

    # From page 28, but obsolete because the repo locations have changed 
    #cat >/etc/yum.repos.d/docker.repo <<-EOF
    #[dockerrepo]
    #name=Docker Repository
    #baseurl=https://yum.dockerproject.org/repo/main/centos/7
    #enabled=1
    #gpgcheck=1
    #gpgkey=https://yum.dockerproject.org/gpg
    #EOF

    # Update from docker docs & other web sources (to work around containerd.io version issues)

    # Install (older version) docker
    dnf -y install docker-ce-3:18.09.1-3.el7

    # Setup firewall ports
    #firewall-cmd --permanent --add-port=6443/tcp
    #firewall-cmd --permanent --add-port=2379-2380/tcp
    #firewall-cmd --permanent --add-port=10250/tcp
    #firewall-cmd --permanent --add-port=10251/tcp
    #firewall-cmd --permanent --add-port=10252/tcp
    #firewall-cmd --permanent --add-port=10255/tcp
    #firewall-cmd –reload

    #modprobe br_netfilter

    #echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

    # Start and enable Docker
    systemctl enable --now docker

    # Add standard user to Docker group
    usermod --append --groups docker developer

    # Setup repository, then install containerd.io package
    #dnf -y install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
    #dnf -y install docker-ce

}

function InstallKubernetes
{

    # These steps from:
    # https://thenewstack.io/how-to-install-a-kubernetes-cluster-on-red-hat-centos-8/

    # Setup repository for kubernetes
    cat >/etc/yum.repos.d/kubernetes.repo <<-EOF
    [kubernetes]
    name=Kubernetes
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    EOF

    dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

    systemctl enable --now kubelet

    ## Manual steps now, but change to sed editing:
    #nano /etc/sysctl.d/k8s.conf
    #net.bridge.bridge-nf-call-ip6tables = 1
    #net.bridge.bridge-nf-call-iptables = 1
    #sysctl --system

    ## Edit fstab
    # nano /etc/fstab
    # /dev/maper/cl-swap  <<-- Comment out this line

    ## Log out of root, then as standard user << ??
    # nano /etc/docker/daemon.json
    # Then paste the following:
    #{
    #  "exec-opts": ["native.cgroupdriver=systemd"],
    #  "log-driver": "json-file",
    #  "log-opts": {
    #    "max-size": "100m"
    #  },
    #  "storage-driver": "overlay2",
    #  "storage-opts": [
    #    "overlay2.override_kernel_check=true"
    #  ]
    #}

    # mkdir --parents /etc/sstemd/system/docker.service.d

    # systemctl daemon-reload
    # systemctl restart docker
    



}

# ====================================================================================
# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================

##########################################################################
# NOTE - First must stop PackageKit or you will hang until it times out
#        which is a really, really long time.
systemctl stop packagekit

PerformUpdate
InstallDocker
Install Kubernetes





