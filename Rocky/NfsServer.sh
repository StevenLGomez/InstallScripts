#!/bin/bash

# Assumes RHEL 8 or derivative
# Minimal install
#
# 2 CPUs
# 4 G RAM
# HD 500 GB - But can vary as needed.
#
# This script creates a Network File System System (NFS) Service
#
# https://computingforgeeks.com/install-and-configure-nfs-server-on-rocky-linux/
#
#

# #############################################################################
#
function PerformUpdate
{
    echo "Function: PerformUpdate starting"

    dnf -y update

    echo "Function: PerformUpdate complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function InstallApplications
{
    echo "Function: InstallApplications starting"

    # Install basic applications
    dnf -y install vim git wget curl

    # Install nfs utility
    dnf -y install nfs-utils

    echo "Function: InstallApplications complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function SetDomain
{
    echo "Function: SetDomain starting"

    # Set domain for network
    sudo sed -i '/^#Domain/s/^#//;/Domain = /s/=.*/= gomezengineering.lan/' /etc/idmapd.conf

    echo "Function: SetDomain complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function PrepareService
{
    echo "Function: PrepareService starting"

    # Create directories to be shared, one for OpenShift Evaluation, one for k8s experimentation
    # Then set their permissions
    mkdir --parents /var/nfs/os-share
    mkdir --parents /var/nfs/k8s-share

    chown nobody:nobody /var/nfs/os-share
    chown nobody:nobody /var/nfs/k8s-share

    # Make associated entries in /etc/exports - NOTE first entry clobbers previous contents
    # Use static IPs to avoid /etc/hosts issues.
    echo '/var/nfs/os-share 10.17.20.112(rw,sync,no_subtree_check)' > /etc/exports
    echo '/var/nfs/k8s-share rocky-master(rw,sync,no_subtree_check)' >> /etc/exports

    echo "Function: PrepareService complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function ConfigureFirewall
{
    echo "Function: ConfigureFirewall starting"

    firewall-cmd --add-service={nfs,nfs3,mountd,rpc-bind} --permanent
    firewall-cmd --reload

    echo "Function: ConfigureFirewall complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function StartService
{
    echo "Function: StartService starting"
    systemctl enable --now nfs-server rpcbind

    echo "Check status of service. NOTE using systemctl status nfs-server will show active (exited)"
    cat /proc/fs/nfsd/threads
    cat /proc/fs/nfsd/versions
    ps aux | grep nfsd

    echo "Function: StartService complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function PrepareClient
{
    echo "Function: PrepareClient starting"

    # See if the shared directories are discoverable
    showmount -e rocky-nfs

    # Create the share mount point
    mkdir /mnt/share

    # Mount the share, then see if it is included in volume list
    mount -t nfs nfs.rocky-nfs:/var/nfs/k8s-share /mnt/share
    df -h

    # Modify fstab to persist through reboots
    nfs.rocky-nfs:/var/nfs/k8s-share      /mnt/share     nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0

    # Test NFS Access
    touch /mnt/share/test.txt
    ls -l /mnt/share/test.txt

    echo "Function: PrepareClient complete"
}
# -----------------------------------------------------------------------------

# #############################################################################
#
function Spare_03
{
    echo "Function: Spare_03 starting"

    echo "Function: Spare_03 complete"
}
# -----------------------------------------------------------------------------



# =============================================================================
# =============================================================================
# Script execution starts below
# =============================================================================
# =============================================================================

PerformUpdate
InstallApplications

# Server specific group
SetDomain
PrepareService
ConfigureFirewall

# Client specific group  This group not tested
# PrepareClient

# For Server & Client
StartService






