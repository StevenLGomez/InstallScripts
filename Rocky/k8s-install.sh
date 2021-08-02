
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

vi /etc/hosts

dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce --nobest --allowerasing
systemctl enable --now docker

usermod -aG docker admin

vi /etc/yum.repos.d/kubernetes.repo

dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
vi /etc/yum.repos.d/kubernetes.repo
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
vi /etc/sysconfig/kubelet 
clear
systemctl enable --now kubelet
systemctl status kubelet
vi /etc/sysconfig/kubelet 
systemctl stop kubelet
systemctl status kubelet
clear
systemctl start kubelet
systemctl status kubelet
systemctl stop kubelet
vi /etc/sysctl.d/k8s.conf
sysctl --system
swapoff -a
vi /etc/fstab
vi /etc/docker/daemon.json
systemctl daemon-reload
systemctl restart docker



