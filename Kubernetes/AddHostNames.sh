#!/bin/bash

# Add host names for Kubernetes cluster members  


##########################################################################
# Add static ip addresses to /etc/hosts to allow hostnames instead of only IPs
function AddHostNames
{
echo "Function: AddHostNames"

if grep -q kmaster01 /etc/hosts; then
    echo "kmaster01 entry already exists in /etc/hosts (skipping)"
else
    echo "Adding kmaster01 to /etc/hosts (Kubernetes Master Node)"
    echo '10.1.1.200     kmaster01  kmaster01.gomezengineering.lan    # Kubernetes master node' >> /etc/hosts
fi

if grep -q knode01 /etc/hosts; then
    echo "knode01 entry already exists in /etc/hosts (skipping)"
else
    echo "Adding knode01 to /etc/hosts (Kubernetes Worker Node 01)"
    echo '10.1.1.205     knode01  knode01.gomezengineering.lan    # Kubernetes worker node 01' >> /etc/hosts
fi

if grep -q knode02 /etc/hosts; then
    echo "knode02 entry already exists in /etc/hosts (skipping)"
else
    echo "Adding knode02 to /etc/hosts (Kubernetes Worker Node 02)"
    echo '10.1.1.206     knode02  knode02.gomezengineering.lan    # Kubernetes worker node 02' >> /etc/hosts
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

