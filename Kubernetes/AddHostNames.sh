#!/bin/bash

# Add host names for Kubernetes cluster members  


##########################################################################
# Add static ip addresses to /etc/hosts to allow hostnames instead of only IPs
function AddHostNames
{
echo "Function: AddHostNames"

if grep -q k-master /etc/hosts; then
    echo "k-master entry already exists in /etc/hosts (skipping)"
else
    echo "Adding k-master to /etc/hosts (Kubernetes Master Node)"
    echo '10.1.1.115     k-master  k-master.gomezengineering.lan    # Kubernetes master node' >> /etc/hosts
fi

if grep -q k-node01 /etc/hosts; then
    echo "k-node01 entry already exists in /etc/hosts (skipping)"
else
    echo "Adding k-node01 to /etc/hosts (Kubernetes Worker Node 01)"
    echo '10.1.1.116     k-node01  k-node01.gomezengineering.lan    # Kubernetes worker node 01' >> /etc/hosts
fi

if grep -q k-node02 /etc/hosts; then
    echo "k-node02 entry already exists in /etc/hosts (skipping)"
else
    echo "Adding k-node02 to /etc/hosts (Kubernetes Worker Node 02)"
    echo '10.1.1.117     k-node02  k-node02.gomezengineering.lan    # Kubernetes worker node 02' >> /etc/hosts
fi

}
# ------------------------------------------------------------------------


# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================

##########################################################################
# ====================================================================================

AddHostNames

