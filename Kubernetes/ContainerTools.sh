#!/bin/bash

RHEL_KUBECTL_VER=v1.22.4

# ====================================================================================
# NOTE that RHEL uses the open source replicant of Docker (podman Pod Manager)
#      The install steps here are from:
#      https://podman.io/getting-started/installation
#      AND
#      https://learningtechnix.wordpress.com/2020/05/16/rhel8-cri-o-container-engine/
#
function InstallPodman
{
    # The following is from the Red Hat reference noted above:
    dnf module install -y container-*
    dnf install -y buildah podman
    
    # Set up rootless container access
    dnf install -y slirp4netns podman
    echo "user.max_user_namespaces=28644" > /etc/sysctl.d/userns.conf
    sysctl -p /etc/sysctl.d/userns.conf
}
# ------------------------------------------------------------------------


# ====================================================================================
# Skopeo - allows working directly with registry images without using build tools
#          This is also installed by InstallPodman, so redundant here, but harmless
function InstallSkopeo
{
    dnf install -y skopeo
}
# ------------------------------------------------------------------------


# ====================================================================================
# Kubectl - allows working with remote installations 
# NOTE - Use curl, since the repository seems to work only on RHEL.
function InstallKubectl
{
    curl -LO https://dl.k8s.io/release/${RHEL_KUBECTL_VER}/bin/linux/amd64/kubectl

    # Validate the binary, by downloading checksum file and comparing against binary
    # curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    curl -LO "https://dl.k8s.io/${RHEL_KUBECTL_VER}/bin/linux/amd64/kubectl.sha256"
    echo "$(<kubectl.sha256) kubectl" | sha256sum --check

    # If the above reported OK, the binary is valid.  Proceed with installation
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # This should report the intended version is installed
    kubectl version --client
}
# ------------------------------------------------------------------------


# ====================================================================================
# ====================================================================================
#
# Script execution begins below
#
# ====================================================================================
# ====================================================================================

InstallPodman
InstallSkopeo

InstallKubectl

