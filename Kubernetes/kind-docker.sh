
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
function InstallDocker
{

    # Download rpm from https://docs/docker.com/desktop/install/fedora

    sudo dnf -y install dnf-plugins-core
    sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    pushd Downloads

    sudo dnf -y install ./docker-desktop-4.23.0-x86_64.rpm

    popd

}
# -----------------------------------------------------------------------------

# #############################################################################
#
function InstallKind
{
    # Download rpm from https://github.com/kubernetes-sigs/kind/releases

    pushd Downloads

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
InstallDocker
InstallKind

# After the above, must:
# 1.) Start Docker Desktop - may require logging in
# 2.) kind create cluster


