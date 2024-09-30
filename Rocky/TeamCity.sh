
# 20240930 - Modified for Rocky 9 installation on esximgmt
#
#            For proper installation, specific configuration steps are requred.
#            See this repository's README.md for further details.

##########################################################################
##########################################################################
##########################################################################

# The TeamCity Server package is stored on internal server
APPLICATION_SERVER_URL=http://10.1.1.20/Applications/TeamCity

TC_NAME=TeamCity
TC_VERSION=2024.07.2
TC_EXT=.tar.gz

# Full name of TeamCity Package: ${TC_NAME}-${TC_VERSION}${TC_EXT}
TC_PKG=${TC_NAME}-${TC_VERSION}${TC_EXT}

TC_URL=${APPLICATION_SERVER_URL}/${TC_PKG}

##########################################################################
#
function PerformUpdate
{
    yum -y update
}
# ------------------------------------------------------------------------

##########################################################################
#
function InstallBasicApplications
{
    yum -y install git wget unzip rsync java-1.8.0-openjdk-headless
    
    if grep -q JAVA_HOME /home/admin/.bashrc; then
        echo "JAVA_HOME already included in admin/.bashrc (skipping)"
    else 
        # Edit /home/admin/.bashrc & add the following to the end of the file:
        echo 'export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk' >> /home/admin/.bashrc
    fi
}
# ------------------------------------------------------------------------


##########################################################################
#
function InstallMariaDb
{
    echo "Function: InstallMariaDb starting"

    dnf -y module install mariadb
    rpm -qi mariadb-server
    systemctl enable --now mariadb

    echo "Function: InstallDataBase complete"
}
# ------------------------------------------------------------------------

##########################################################################
# 
function InstallTeamCity
{
    echo "Function: InstallTeamCity starting"

    wget ${TC_URL} --directory-prefix /opt

    pushd /opt

    echo ${TC_PKG}
    tar xvf ${TC_PKG}
    rm -f ${TC_PKG}
    
    popd

    # Allow TeamCity write permissions to its directories
    chown -R admin:admin /opt/TeamCity
    chown -R admin:admin /opt/TCData
    
    # Open the necessary ports for TeamCity web services
    firewall-cmd --zone=public --permanent --add-port=8111/tcp
    firewall-cmd --reload

    echo "Function: InstallTeamCity complete"
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

PerformUpdate
InstallBasicApplications
InstallMariaDb
InstallTeamCity

