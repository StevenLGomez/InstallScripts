#!/bin/bash

# DevAgent.sh 
# Supports basic C/C++, Python & Source documentation activities
# on a TeamCity compatible build agent virtual machine

# Virtual Machine Definition
# 4 CPUs
# 4096 MB RAM
# 75 G Hard Disk
# Built from Rocky 10.2 ISO
# EFI enabled
# Minimal Install

# Definitions to define URLs for downloading Applications (from devserver Apache)
APPLICATION_SERVER_URL=http://10.1.1.20/Applications

# Rocky 10.2 ships with python 3.12, install here not necessary
# PYTHON_VER=3.11.16
# PYTHON_SRC=Python-${PYTHON_VER}
# PYTHON_PKG=${PYTHON_SRC}.tgz
# PYTHON_URL=https://www.python.org/downloads/source/${PYTHON_PKG}

#SONAR_VER=3.0.1.733
#SONAR_SCANNER=sonar-scanner-cli-${SONAR_VER}-linux
#SONAR_SCANNER_ZIP=${SONAR_SCANNER}.zip
#SONAR_SCANNER_URL=R{PACKAGE_URL}/Packages/SonarQube/${SONAR_SCANNER_ZIP}
#SONAR_SCANNER_DIR=sonar-scanner-${SONAR_VER}-linux

# TODO - Modify to use direct download from doxygen.nl site
# https://www.doxygen.nl/files/doxygen-1.18.0.src.tar.gz
DOXYGEN_VER=1.18.0
DOXYGEN=doxygen-${DOXYGEN_VER}.src.tar.gz
DOXYGEN_URL=${APPLICATION_URL}/Doxygen/${DOXYGEN}

TEAMCITY_SERVER=http://10.1.1.30:8111

##########################################################################
# Install additional repositories to assist with virtualization support
# For more information: https://fedoraproject.org/wiki/EPEL
function InstallEpelRepository
{
    echo "Function: InstallEpelRepository"
    
    # Use this command, from: https://wiki.centos.org/AdditionalResources/Repositories
    dnf --enablerepos=extras install -y epel-release
}

##########################################################################
# Normal update...
function PerformUpdate
{
    dnf -y --nobest update
}
# ------------------------------------------------------------------------

##########################################################################
# Disable SELinux - seemed to help VirtualBox installations, but not recommended normally
# The second line here keeps it disabled after reboots
function DisableSELinux
{
    echo "Function: DisableSELinux"
    setenforce 0
    echo "SELINUX=disabled" > /etc/selinux/config
}
# ------------------------------------------------------------------------

##########################################################################
# Perform update and install items that may not have been included in 
# the kickstart installation.
# Packages can be repeated without concern (will be skipped if already installed)
function InstallDevelopmentApplications
{
    echo "Function: InstallDevelopmentApplications"
    dnf -y install subversion git wget

    # Install development & test support items
    dnf -y groupinstall "Development Tools"
    dnf -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel xz-devel libpng libpng-devel
    dnf -y install cmake
    dnf -y install flex
    dnf -y install bison

    # NOT available: libpcap-devel
    # NOT available: python-devel
}
# ------------------------------------------------------------------------

##########################################################################
# Install additional Python libraries 
# Items previously installed will be skipped
function InstallPythonExtensions
{
    echo "Function: InstallPythonExtensions"

    # The no proxy version
    /usr/local/bin/pip3.8 install --upgrade pip setuptools
    /usr/local/bin/pip3.8 install numpy
    /usr/local/bin/pip3.8 install matplotlib
    /usr/local/bin/pip3.8 install cython
    /usr/local/bin/pip3.8 install pexpect
    /usr/local/bin/pip3.8 install robotframework
    /usr/local/bin/pip3.8 install pyusb
}
# End of Python extension library installation section
# ------------------------------------------------------------------------

##########################################################################
# Check for existence of the CPPUnit library on this VM and install if not already there
function InstallCPPUnit
{
echo "Function: InstallCPPUnit"

    dnf install -y cppunit
    dnf install -y cppunit-devel   # Perhaps only needed to "develop" cppunit
}
# End of CPPUnit installation section
# ------------------------------------------------------------------------

##########################################################################
# Install MinGW-W64 (For building 32 & 64 bit Windows applications on Linux) 
# Steps below are from duck.ai
function InstallMingw32
{
    # Enable CodeReady Builder Repository
    dnf config-manager --set-enabled crb
    dnf install -y mingw-w64-tools

    # dnf -y install mingw32-gcc mingw32-libxml2 mingw32-minizip mingw32-libwebp 
    # dnf -y install mingw32-pdcurses mingw32-gcc-c++
}
# ------------------------------------------------------------------------

##########################################################################
# Install TeamCity Build Agent - instructions from duck.ai 
function InstallTeamCityBuildAgent
{
    # Install java
    dnf install -y java-11-openjdk
    java -version

    # Create directory structure for agent, then download ZIP from TC Server
    mkdir --parents /opt/teamcity-agent
    cd /opt/teamcity-agent
    wget $TEAMCITY_SERVER/update/buildAgent.zip

    # Display what was downloaded, then unzip it
    ls -al
    unzip buildAgent.zip

    # After the above, edit conf/buildAgent.properties
    # serverUrl=$TEAMCITY_SERVER  << Expand manually
    # name=<MY-AGENT>
    # workDir=../work
    # tempDir=../temp
    # systemDir=../system

    # Start the agent 
    # bin/agent.sh start

    # Authorize the agent on TC Server
    # Agents -> Unauthorized

    # Check logs
    # tail -f logs/teamcity-agent.log
}
# ------------------------------------------------------------------------




# ====================================================================================
# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================

##########################################################################
# NOTE - First must stop PackageKit or you will hang until it times out
#        which is a really, really long time.
systemctl stop packagekit

PerformUpdate
InstallDevelopmentApplications

# InstallPython

# Note that installing EPEL seems to work best BEFORE updating
# InstallEpelRepository      # Enables the EPEL repository 

# DisableSELinux


# InstallPythonExtensions
# InstallCPPUnit
# InstallMingw32

InstallTeamCityBuildAgent

