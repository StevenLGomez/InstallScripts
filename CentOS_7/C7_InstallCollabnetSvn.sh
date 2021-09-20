#!/bin/bash

# Proposed installation steps:
#
#  1.) Create the VM with 16G primary drive
#  2.) Perform Centos 7 MINIMAL install
#  3.) During install, create root & admin accounts
#  4.) Allow installation time to complete, then reboot (disconnect CD image)
#  5.) Test logging in as root & admin
#  6.) As root, install Git -> yum -y install git
#  7.) git clone https://github.com/gesllc/InstallScripts.git
#  8.) shutdown -h now
#  9.) Create secondary drive in vCenter
# 10.) Power on, then as root:
#     fdisk /dev/sdb
#         n (to create new partitition)
#         p (to make this a primary partition)
#         1 (select partition 1)
#         Enter (start at default sector)
#         Enter (default to last cylinder to use all space)
#         w (write partition table & exit)
#
#     Then run:
#
#     mkfs -t ext4 /dev/sdb1
#
# 10.) Run the following command to connect to new drive at boot time:
#     echo '/dev/sdb1	/opt/csvn	ext4	defaults	1	1' >> /etc/fstab
# 
# 11.) Reboot and confirm the secondary drive is properly mounted (use df -h)
# 12.) Run this script
# 
# 
# 
# Had a horrible time downloading the CollabNet Subversion Edge package.
# Here is the md5 hash for a sanity check
#
# MD5SUM of CollabNet Installer: 0862eaba2dd1b048dc6c10cb2b1e910b <= Does not match downloaded package !!
# 
# 20210920
# Had issues with JAVA_HOME  finally settled in on JAVA_HOME=/usr/lib/jvm/jre-openjdk

# ========================================================================
# Variable definitions

INTERNAL_SERVER_URL=http://10.1.1.26/Applications

CSVN_ZIP=CollabNetSubversionEdge-5.2.4_linux-x86_64.tar.gz
CSVN_APP=CollabNetSubversionEdge-5.2.4_linux-x86_64.tar
CSVN_URL=${INTERNAL_SERVER_URL}/ServerApplications/${CSVN_ZIP}

# ========================================================================

##########################################################################
# 
function PerformUpdate
{
    yum -y update
}
# ------------------------------------------------------------------------

function InstallPackages
{
    yum -y install perl
    yum -y install wget
    yum -y install git
    yum -y install java-1.8.0-openjdk.x86_64
}
# ------------------------------------------------------------------------


##########################################################################
# 
function SetupJavaHome
{
    echo 'export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk-1.8.0.222.b10-0.el7_6.x86_64' >> /home/admin/.bash_profile
}
# ------------------------------------------------------------------------

##########################################################################
# 
function InstallCollabNetSubversion
{
    wget ${CSVN_URL} --directory-prefix=/opt
    md5sum /opt/${CSVN_ZIP} > /opt/CsvnMd5Log.txt

    chown -R admin:admin /opt/csvn

    cd /opt
    # runuser admin -c 'tar zxf CollabNetSubversionEdge-5.2.4_linux-x86_64.tar.gz'
    gunzip ${CSVN_ZIP}
    export CSVN_EXP=${CSVN_APP}
    runuser admin -c 'tar xvf ${CSVN_EXP}'
}
# ------------------------------------------------------------------------

##########################################################################
# Notes from CollabNet Subversion web site:
# SVN Edge uses the following ports:
# 3343 - http access to web console
# 4434 - https access to web console
# 
# 18080 - https access to viewvc web interface
# 
# XXX - whatever port you configure you want Apache to use from the SVN
#       Edge UI.  Normally, this would be 80 or 443
#
function SetupFirewallRules
{

    firewall-cmd --zone=public --permanent --add-port=3343/tcp
    firewall-cmd --zone=public --permanent --add-port=4434/tcp
    firewall-cmd --zone=public --permanent --add-port=18080/tcp
    firewall-cmd --reload
}
# ------------------------------------------------------------------------

##########################################################################
# 
function AddLocalHostNames
{
    if grep -q dionysus /etc/hosts; then
        echo "dionysus entry already exists in /etc/hosts (skipping)"
    else
        echo "Adding dionysus to /etc/hosts (Subversion server)"
        echo '10.1.1.20     dionysus  dionysus.gomezengineering.lan    # Subversion' >> /etc/hosts
    fi

    if grep -q teamcity /etc/hosts; then
        echo "teamcity entry already exists in /etc/hosts (skipping)"
    else
        echo "Adding teamcity to /etc/hosts (Continuous Integration server)"
        echo '10.1.1.21     teamcity  teamcity.gomezengineering.lan    # TeamCity' >> /etc/hosts
    fi
}
# ------------------------------------------------------------------------


# =============================================================================
# =============================================================================
# =============================================================================
#
# Script execution begins here
#
# =============================================================================

PerformUpdate
InstallPackages
SetupJavaHome
SetupFirewallRules
InstallCollabNetSubversion
AddLocalHostNames


