
# Steps to install Kubernetes KIND cluster on Fedora 38.1 - Rocky 8 VM
#
# VM Configuration
# CPUs:		8
# Mem		16 Gb
# Hard Disk	350 Gb - Thick lazy
# IP		10.17.20.129
#
# Installed Fedora - Rocky as 'Server with GUI' to have web browser
# Users: root & developer, and added developer with visudo
#
# ======================================================================
# Install notes from 'Acing The Certified Kubernetes Administrator' book
#
# Docker desktop from:	https://docker.com/products/docker-desktop
# KIND from:		https://github.com/kubernetes-sigs/kind/releases
#
#

# #############################################################################
#
function PerformUpdate
{
    echo "Function: PerformUpdate starting"

    sudo dnf -y update

    # Install basic applications
    sudo dnf -y install vim git wget curl

    echo "Function: PerformUpdate complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function InstallContainerRunTime
{
    # Setup repositories
    sudo dnf -y install dnf-plugins-core
    sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    # Install the latest version 
    sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

}
# -----------------------------------------------------------------------------

# #############################################################################
#
function InstallKind
{
    # Download rpm from https://github.com/kubernetes-sigs/kind/releases into ~/Downloads
    wget $KIND_DL_URL --directory-prefix=$HOME/Downloads

    pushd $HOME/Downloads

    sudo chmod +x ./kind-linux-amd64
    sudo mv ./kind-linux-amd64 /usr/local/bin/kind

    popd
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function InstallKubectl
{
    # Switch to the $HOME/Downloads directory
    pushd $HOME/Downloads

    # Download the latest version
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    # Download the kubectl checksum file
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

    # Validate kubectl binary against the checksum file, sleep to allow output viewing
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sleep 5

    # Install to $HOME/.local/bin (which is already in Fedora's path)
    chmod +x kubectl
    mkdir -p ~/.local/bin
    mv ./kubectl ~/.local/bin/kubectl

}
# -----------------------------------------------------------------------------



# =============================================================================
# =============================================================================
# Script execution starts below
# =============================================================================
# =============================================================================

PerformUpdate	
InstallKubectl
InstallContainerRunTime
InstallKind

