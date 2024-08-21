#!/bin/bash

# This script adds selected groups of entries to /etc/hosts for supporting
# network access to these systems.
#
# The groups are limited to basic sets; if more than one set is desired, re-run
# the script with a different group each time.
#
# Running script with no parameters will display the supported options

# ########################################################################
# Add host names that are included in BMX DNS lookup tables
# For use with systems that cannot reach DNS servers.
function AddCommonHostNames
{
    if grep -q usstlsvn02 /etc/hosts; then
	echo "usstlsvn02 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding usstlsvn02 to /etc/hosts"
	echo '10.1.1.6     usstlsvn02  usstlsvn02.corp.internal # Main Subversion Server' >> /etc/hosts
    fi

    if grep -q usstlbas02 /etc/hosts; then
	echo "usstlbas02 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding usstlbas02 to /etc/hosts"
	echo '10.1.1.10    usstlbas02  usstlbas02.corp.internal # TeamCity Server' >> /etc/hosts
    fi

    if grep -q usstllic01 /etc/hosts; then
	echo "usstllic01 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding usstllic01 to /etc/hosts"
	echo '10.1.1.13    usstllic01  usstllic01.corp.internal # License Server (W7)' >> /etc/hosts
    fi

    if grep -q usstlgit03 /etc/hosts; then
	echo "usstlgit03 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding usstlgit03 to /etc/hosts"
	echo '10.1.1.23    usstlgit03  usstlgit03.corp.internal # Production Git Server (Atlassian Bitbucket on RHEL 7)' >> /etc/hosts
    fi

    if grep -q sonarqube /etc/hosts; then
	echo "sonarqube entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding sonarqube to /etc/hosts"
	echo '10.1.1.29    sonarqube   sonarqube.corp.internal # SonarQube Server' >> /etc/hosts
    fi

    if grep -q usstlweb02 /etc/hosts; then
	echo "usstlweb02 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding usstlweb02 to /etc/hosts"
	echo '10.1.1.62    usstlweb02   usstlweb02.corp.internal # Engineering Web Server' >> /etc/hosts
    fi
}
# ====================================================================================



# ########################################################################
# Add host names for development systems (not commonly used by everyone)
#
function AddDevelopmentHostNames
{
    if grep -q usstlsvn01 /etc/hosts; then
	echo "usstlsvn01 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding usstlsvn01 to /etc/hosts"
	echo '10.1.1.5     usstlsvn01  usstlsvn01.corp.internal # Dev Subversion Server' >> /etc/hosts
    fi

    if grep -q usstlbas01 /etc/hosts; then
	echo "usstlbas01 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding usstlbas01 to /etc/hosts"
	echo '10.1.1.9    usstlbas01  usstlbas01.corp.internal # TeamCity Server' >> /etc/hosts
    fi

    if grep -q usstlbus01 /etc/hosts; then
	echo "usstlbus01 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding usstlbus01 to /etc/hosts"
	echo '10.1.1.70   usstlbus01  usstlbus01.corp.internal # TeamCity Server' >> /etc/hosts
    fi

    if grep -q usstlweb01 /etc/hosts; then
	echo "usstlweb01 entry already exists in /etc/hosts (skipping)"
    else
	echo "Adding usstlweb01 to /etc/hosts"
	echo '10.1.1.61    usstlweb01   usstlweb01.corp.internal # Engineering Web Server' >> /etc/hosts
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
    echo "    COMMON        Adds information for common systems (that are also in IS DNS tables)  "
    echo "    DEVELOPMENT   Adds development systems (systems that are NOT in the IS DNS tables)  "
    echo "    KUBERNETES    Adds Kubernetes cluster nodes                                         "
    echo ""
    echo "Usage: $0 COMMON || DEVELOPMENT || KUBERNETES "
    exit
fi

# Echo the valid command line entry
echo $0 $1

if [ "$1" = "COMMON" ]
then
    echo "Addming COMMON system information to hosts file"
    AddCommonHostNames
fi

if [ "$1" = "DEVELOPMENT" ]
then
    echo "Addming DEVELOPMENT system information to hosts file"
    AddDevelopmentHostNames
fi

if [ "$1" = "KUBERNETES" ]
then
    echo "Addming KUBERNETES node information to hosts file"
    AddClusterHostNames
fi

