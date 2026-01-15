#!/bin/bash

# This script adds selected groups of entries to /etc/hosts for supporting
# network access to these systems.
#
# The groups are limited to basic sets; if more than one set is desired, re-run
# the script with a different group each time.
#
# Running script with no parameters will display the supported options

# ########################################################################
# Add host names for development systems (not commonly used by everyone)
function AddCorporateHostNames
{
	echo "Deprecated"
}
# ====================================================================================



# ########################################################################
# Add host names for common  systems
#
function AddCommonHostNames
{
    if grep -q porker /etc/hosts; then
	echo "porker entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding porker to /etc/hosts"
	echo '10.1.1.4     porker  porker.corp.internal # ReadyNAS' >> /etc/hosts
    fi

    if grep -q apollo /etc/hosts; then
	echo "apollo entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding apollo to /etc/hosts"
	echo '10.1.1.7     apollo  apollo.corp.internal # ESXI - Virtual machines' >> /etc/hosts
    fi

    if grep -q devserver /etc/hosts; then
	echo "devserver entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding devserver to /etc/hosts"
	echo '10.1.1.20    devserver  devserver.corp.internal # TeamCity Server' >> /etc/hosts
    fi

    if grep -q hermes /etc/hosts; then
	echo "hermes entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding hermes to /etc/hosts"
	echo '10.1.1.21    hermes  hermes.corp.internal # TeamCity Server' >> /etc/hosts
    fi
}

# ====================================================================================



# ########################################################################
# Add host names for Kubernetes systems
# Systems that need these probably don't need ANY others.
#
function AddClusterHostNames
{
    if grep -q k-master /etc/hosts; then
    echo "k-master entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding k-master to /etc/hosts (ESXi Server)"
	echo '10.1.1.115     k-master  k-master.corp.internal    # Kubernetes Master' >> /etc/hosts
    fi

    if grep -q k-node01 /etc/hosts; then
    echo "k-node01 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding k-node01 to /etc/hosts (ESXi Server)"
	echo '10.1.1.116     k-node01  k-node01.corp.internal    # Kubernetes Worker 01' >> /etc/hosts
    fi

    if grep -q k-node02 /etc/hosts; then
    echo "k-node02 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding k-node02 to /etc/hosts (ESXi Server)"
	echo '10.1.1.117     k-node02  k-node02.corp.internal    # Kubernetes Worker 02' >> /etc/hosts
    fi
}
# ====================================================================================



# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================
# ====================================================================================


# Require one parameter
# $1 = Option String
#
# Supported options defined in if statement below
#

if [ -z "$1" ]
then
    echo "ERROR: Missing parameter - must specify which group of hosts to add"
    echo ""
    echo "Supported Host Groups:"
    echo "    CORPORATE        Adds information for development systems  "
    echo "    COMMON   Add common systems "
    echo "    KUBERNETES    Adds Kubernetes cluster nodes                                         "
    echo ""
    echo "Usage: $0 CORPORATE || COMMON || KUBERNETES "
    exit
fi

# Echo the valid command line entry
echo $0 $1

if [ "$1" = "CORPORATE" ]
then
    echo "Addming CORPORATE system information to hosts file"
    echo "DEPRECATED - Corporate configuration carry over"
    # AddDevelopmentHostNames
fi

if [ "$1" = "COMMON" ]
then
    echo "Addming COMMON system information to hosts file"
    AddCommonHostNames
fi

if [ "$1" = "KUBERNETES" ]
then
    echo "Addming KUBERNETES node information to hosts file"
    AddClusterHostNames
fi

