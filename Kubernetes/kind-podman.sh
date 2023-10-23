
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
# KIND from:		https://github.com/kubernetes-sigs/kind/releases
#
# To create a cluster:
# kind create cluster


# URL to download Kubernetes In Docker directly from github
KIND_DL_URL=https://github.com/kubernetes-sigs/kind/releases/download/v0.20.0/kind-linux-amd64

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
    echo "Function: InstallContainerRunTime starting"

    if [ $CONTAINER_RUNTIME = "PODMAN" ]
    then
        echo "Installing Podman container runtime"
        sudo dnf -y install podman
    fi

    if [ $CONTAINER_RUNTIME = "DOCKER" ]
    then
        echo "Installing Docker container runtime"

        # Setup repositories
        sudo dnf -y install dnf-plugins-core
        sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

        # Install the latest version 
        sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    echo "Function: InstallContainerRunTime complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function InstallKind
{
    echo "Function: InstallKind starting"

    # Download rpm from https://github.com/kubernetes-sigs/kind/releases
    wget $KIND_DL_URL 

    sudo chmod +x ./kind-linux-amd64
    sudo mv ./kind-linux-amd64 /usr/local/bin/kind

    echo "Function: InstallKind complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function InstallKubectl
{
    echo "Function: InstallKubectl starting"

    # Download the latest version
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    # Download the kubectl checksum file
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

    # Validate kubectl binary against the checksum file, sleep to allow output viewing
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sleep 5

    # Install to $HOME/.local/bin (which is already in Fedora's path)
    chmod +x kubectl
    mkdir -p /home/$USER/.local/bin
    sudo mv ./kubectl /usr/local/bin/kubectl

    # Remove the checksum file
    rm kubectl.sha256

    echo "Function: InstallKubectl complete"
}
# -----------------------------------------------------------------------------


# =============================================================================
# =============================================================================
# Script execution starts below
# =============================================================================
# =============================================================================

# Requires one parameter
# $1 = Option String
#
# Supported options defined in if statement below
#

if [ -z "$1" ]
then
    echo "ERROR: Missing parameter - must specify PODMAN or DOCKER container runtime"
    echo ""
    echo "Supported Options:"
    echo "    PODMAN    Installs Podman container runtime"
    echo "    DOCKER    Installs Docker container runtime"
    echo ""
    echo "Usage: $0 PODMAN || DOCKER"
    exit
fi

# Echo the valid command line entry
echo $0 $1

if [ "$1" = "PODMAN" ]
then
    echo "Will install PODMAN container runtime"
    CONTAINER_RUNTIME="PODMAN"
fi

if [ "$1" = "DOCKER" ]
then
    echo "Will install DOCKER container runtime"
    CONTAINER_RUNTIME=DOCKER
fi

echo "Applying CONTAINER_RUNTIME:  ${CONTAINER_RUNTIME}"

PerformUpdate	
InstallKubectl
InstallContainerRunTime
InstallKind

