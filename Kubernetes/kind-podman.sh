
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
#

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
    sudo dnf -y install podman
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



# =============================================================================
# =============================================================================
# Script execution starts below
# =============================================================================
# =============================================================================

PerformUpdate	
InstallContainerRunTime
InstallKind

# After the above, must:
# 2.) kind create cluster


