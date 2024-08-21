#!/bin/bash

# Definitions to define URLs for downloading Applications
APPLICATION_SERVER_URL=http://10.1.1.26/Applications

PYTHON_VER=3.8.8
PYTHON_SRC=Python-${PYTHON_VER}
PYTHON_PKG=${PYTHON_SRC}.tgz
PYTHON_URL=https://www.python.org/downloads/source/${PYTHON_PKG}

#SONAR_VER=3.0.1.733
#SONAR_SCANNER=sonar-scanner-cli-${SONAR_VER}-linux
#SONAR_SCANNER_ZIP=${SONAR_SCANNER}.zip
#SONAR_SCANNER_URL=R{PACKAGE_URL}/Packages/SonarQube/${SONAR_SCANNER_ZIP}
#SONAR_SCANNER_DIR=sonar-scanner-${SONAR_VER}-linux

#SLICK_EDIT_VER=2400020
#SLICK_EDIT=se_${SLICK_EDIT_VER}_linux64.tar.gz
#SLICK_EDIT_URL=${APPLICATION_URL}/SlickEdit/Linux/${SLICK_EDIT}

DOXYGEN_VER=1.8.18
DOXYGEN=doxygen-${DOXYGEN_VER}.src.tar.gz
DOXYGEN_URL=${APPLICATION_URL}/Doxygen/${DOXYGEN}

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
# Install Dynamic Kernel Module Support (Mandatory for VBox Guest Additions, helpful for VMware)
function InstallDKMS
{
    echo "Function: InstallDKMS"
    dnf -y --enablerepo=epel install dkms
}
# ------------------------------------------------------------------------

##########################################################################
# Install Dynamic Kernel Module Support (Mandatory for VBox Guest Additions, helpful for VMware)
function InstallFilezilla
{
    echo "Function: InstallFilezilla"
    dnf -y --enablerepo=epel install filezilla
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
    dnf -y install subversion
    dnf -y install git
    dnf -y install gedit

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
# Create a directory to use for mounting the host share
# With this directory created, VMware Player VMs can mount the shared directory using
# (as developer)  /usr/bin/vmhgfs-fuse /home/developer/HostShare 
function CreateHostShareDirectory
{
    echo "Function: CreateHostShareDirectory"
    if [ ! -d "/home/developer/HostShare" ]; then
        echo "Creating host share directory (HostShare)"
        mkdir /home/developer/HostShare
        chown developer:developer /home/developer/HostShare
    else
        echo "HostShare directory appears to have previously been created (skipping)"
    fi
}
# End of share directory creation
# ------------------------------------------------------------------------

##########################################################################
# Check for the previous installation of Python 3.8, and if not installed,
# create a working directory (projects), download source package from 
# internal server, extract, configure, make, install.
#
# Note: Also take a peek at this website, has good explanation of ./configure
#       that may be advisable moving forward.
# https://danieleriksson.net/2017/02/08/how-to-install-latest-python-on-centos/
#
function InstallPython
{
    echo "Function: InstallPython"
    if [ -f /usr/local/bin/python3.8 ]; then
        echo "Executable for Python 3.8 already exists (skipping)"
    else
        echo "Python 3.8 Executable not in expected path, performing installation"

        mkdir ~/projects
        cd ~/projects

        # Use wget to pull the Python package
        wget ${PYTHON_URL}

        # Unpack, configure and make Python 3.8
        tar xzf ${PYTHON_PKG}
        cd ~/projects/${PYTHON_SRC}

        ./configure --enable-optimizations
        make

        # Install Python into /usr/local/bin
        make altinstall

        # Return to home directory and remove the Python installation directory tree
        cd
        rm -Rf ~/projects

        # Add an alias for Python 3.8 to avoid needing to enter /usr/local/bin/python3.8
        echo 'alias py38="/usr/local/bin/python3.8"' >> /home/developer/.bashrc  

    fi
}
# End of Python installation section
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

    if [ -f /usr/local/lib/libcppunit.so ]; then
    echo "CPPUnit library file already exists (skipping build/config of CPPUnit)"
    else
        echo "CPPUnit library file does not exist, performing installation"

        # As with installing Python, create a projects directory then move into it
        mkdir projects
        cd projects

        # CPPUnit source is kept in Subversion, check it out from:
        svn checkout https://10.17.20.6:18080/svn/tools/tools/cppunit/trunk cppunit

        cd cppunit

        # This command is required to correct a configuration error in the CPPUnit source package
        # (./configure would fail because it was not executable)
        chmod u+x configure

        # These steps configure, build, test then install CPPUnit
        ./autogen.sh
        ./configure
        make
        make check
        make install

        # Clean up after build & install process
        cd
        rm -Rf projects

        # Make entry in developer/.bash_profile for location of cppunit library (if not already there)
        if grep -q LD_LIBRARY_PATH /home/developer/.bash_profile; then
            echo "LD_LIBRARY_PATH entry already exists in /home/developer/.bash_profile (skipping)"
        else
            echo "Adding LD_LIBRARY_PATH entry to /home/developer/.bash_profile"
            echo '' >> /home/developer/.bash_profile
            echo 'LD_LIBRARY_PATH=/usr/local/lib' >> /home/developer/.bash_profile
            echo 'export LD_LIBRARY_PATH' >> /home/developer/.bash_profile
        fi
    fi
}
# End of CPPUnit installation section
# ------------------------------------------------------------------------

##########################################################################
# Check for existence of the Sonar Scanner on this VM and install if not already there
function InstallSonarScanner
{
echo "Function: InstallSonarScanner"

    if [ -f /opt/sonar-scanner-3.0.1.733-linux/conf/sonar-scanner.properties ]; then
        echo "Sonar Scanner (configuration file) already exists (skipping)"
    else
    wget ${SONAR_SCANNER} --directory-prefix /opt
        cd /opt
        unzip sonar-scanner-cli-3.0.1.733-linux.zip
        chown -R developer:root sonar-scanner-3.0.1.733-linux

        # Add URL of sonarqube server below their example line
        sed -i '/sonar.host.url/ a sonar.host.url=http://sonarqube:9000' sonar-scanner-3.0.1.733-linux/conf/sonar-scanner.properties

        # Add source encoding definition line below their example
        sed -i '/sonar.sourceEncoding/ a sonar.sourceEncoding=ISO8859-1' sonar-scanner-3.0.1.733-linux/conf/sonar-scanner.properties

        rm sonar-scanner-cli-3.0.1.733-linux.zip
        cd

        # Add an alias for the honkin' long scanner path/command
        echo 'alias sonarscan="/opt/sonar-scanner-3.0.1.733-linux/bin/sonar-scanner"' >> /home/developer/.bashrc  
    fi
}
# End of Sonar Scanner configuration section
# ------------------------------------------------------------------------

##########################################################################
InstallGoogleChrome
{
echo "Function: InstallGoogleChrome"

if [ -f /etc/yum.repos.d/google-chrome.repo ]; then
    echo "Google Chrome repository already exists (skipping)"
else

    echo "[google-chrome]" > /etc/yum.repos.d/google-chrome.repo
    echo "name=google-chrome" >> /etc/yum.repos.d/google-chrome.repo
    echo "baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64" >> /etc/yum.repos.d/google-chrome.repo
    echo "enabled=1" >> /etc/yum.repos.d/google-chrome.repo
    echo "gpgcheck=1" >> /etc/yum.repos.d/google-chrome.repo
    echo "gpgkey=https://dl.google.com/linux/linux_signing_key.pub" >> /etc/yum.repos.d/google-chrome.repo

    yum -y install google-chrome-stable
fi
}
# End of Google Chrome section
# ------------------------------------------------------------------------

##########################################################################
# Install SlickEdit
function PrepareSlickEdit
{
echo "Function: PrepareSlickEdit"

if [ ! -f "/opt/${SLICK_EDIT}" ]; then
    echo "Downloading & extracting SlickEdit package"
    wget ${SLICK_EDIT_URL} --directory-prefix /opt
    cd /opt
    tar -xvf ${SLICK_EDIT} 
    
    # TODO - Consider pulling the license file while you're here
    
    cd

else
    echo "SlickEdit directory appears to have previously been created (skipping)"
fi

}
# End of SlickEdit creation
# ------------------------------------------------------------------------

##########################################################################
# Install Mingw32 (For building Windows applications on Linux) 
# Tutorial: https://fedoraproject.org/wiki/MinGW/Tutorial
# Core Utilities code: https://usstlsvn02:18080/svn/vendor/GNU/coreutils
# See: build-aux/gen-lists-of-programs.sh
function InstallMingw32
{
    # dnf -y install mingw32-gcc mingw32-libxml2 mingw32-minizip mingw32-libwebp 
    # dnf -y install mingw32-pdcurses mingw32-gcc-c++
    dnf -y install ming32-*
}
# ------------------------------------------------------------------------

##########################################################################
# Add static ip addresses to /etc/hosts to allow hostnames instead of only IPs
function UpdateEtcHosts
{
echo "Function: UpdateEtcHosts"

if grep -q esximgmt /etc/hosts; then
    echo "esximgmt entry already exists in /etc/hosts (skipping)"
else
    echo "Adding esximgmt to /etc/hosts (ESXi Server)"
    echo '10.1.1.5     esximgmt  esximgmt.gomezengineering.lan    # Infrastructure Server' >> /etc/hosts
fi

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

if grep -q talos /etc/hosts; then
    echo "talos entry already exists in /etc/hosts (skipping)"
else
    echo "Adding talos to /etc/hosts (local backup server)"
    echo '10.1.1.22    talos  talos.gomezengineering.lan    # Local backup server' >> /etc/hosts
fi

if grep -q hermes /etc/hosts; then
    echo "hermes entry already exists in /etc/hosts (skipping)"
else
    echo "Adding hermes to /etc/hosts (public web server)"
    echo '10.1.1.25    hermes  hermes.gomezengineering.lan    # Public web server' >> /etc/hosts
fi

if grep -q devserver /etc/hosts; then
    echo "devserver entry already exists in /etc/hosts (skipping)"
else
    echo "Adding devserver to /etc/hosts (local web development server)"
    echo '10.1.1.26    devserver  devserver.gomezengineering.lan    # Development web server' >> /etc/hosts
fi

if grep -q sonarqube /etc/hosts; then
    echo "sonarqube entry already exists in /etc/hosts (skipping)"
else
    echo "Adding sonarqube to /etc/hosts"
    echo '10.1.1.36    sonarqube   sonarqube.gomezengineering.lan    # SonarQube' >> /etc/hosts
fi

if grep -q porker /etc/hosts; then
    echo "porker entry already exists in /etc/hosts (skipping)"
else
    echo "Adding porker to /etc/hosts"
    echo '10.1.1.45    porker   porker.gomezengineering.lan    # NetGear ReadyNAS' >> /etc/hosts
fi

if grep -q apollo /etc/hosts; then
    echo "apollo entry already exists in /etc/hosts (skipping)"
else
    echo "Adding apollo to /etc/hosts"
    echo '10.1.1.70    apollo   apollo.gomezengineering.lan    # Logitech music server' >> /etc/hosts
fi

}
# Local Static IP updates finished
# ------------------------------------------------------------------------

##########################################################################
# Install Sqlite Studio 
# https://github.com/pawelsalawa/sqlitestudio/wiki/Instructions_for_compilation_under_Linux#what-you-need 
# https://jdhao.github.io/2017/09/04/install-gcc-newer-version-on-centos/
#
# TODO - Seems this wasn't succeeding on last attempt
function InstallSqliteStudio
{
    dnf -y install sqlite
    dnf -y install qt5-qtbase-devel

    # This clone operation creates the sqlitestudio directory with the code
    git clone https://github.com/pawelsalawa/sqlitestudio.git

    mkdir sqlitestudio/output
    mkdir sqlitestudio/output/build

    cd sqlitestudio/output/build

    /usr/lib64//qt5/bin/qmake ../../SQLiteStudio3
    make

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
InstallPython

# Note that installing EPEL seems to work best BEFORE updating
# InstallEpelRepository      # Enables the EPEL repository 
# InstallDKMS                # REQUIRES EPEL Repository Installs DKMS (for virtualization support)
# InstallFilezilla           # REQUIRES EPEL Repository Installs FileZilla

# DisableSELinux

# CreateHostShareDirectory

InstallPythonExtensions
# InstallCPPUnit
# InstallSonarScanner
# InstallGoogleChrome
InstallMingw32
# InstallSqliteStudio
# PrepareSlickEdit
UpdateEtcHosts

