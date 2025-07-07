#!/bin/bash

# https://www.ansible.com/resources/videos/quick-start-video
# 1.) Enable 'Extras' ad 'Optional' yum repos
# 2.) Install Ansible
# 
# docs.ansible.com/ansible/intro_installation.html
#
# The O'Reilly Tutorial Book makes use of Vagrant commands, which
# haha, requires VirtualBox.  So an attempt was made to install &
# run VB using the following block of commands.  It of course fails,
# as does VirtualBox in most other environments.
#
# wget https://releases.hashicorp.com/vagrant/2.2.9/vagrant_2.2.9_x86_64.rpm
# wget https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo
# mv virtualbox.repo /etc/yum.repos.d/
# wget -q https://www.virtualbox.org/download/oracle_vbox.asc
# rpm --import oracle_vbox.asc
# dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
# dnf -y install binutils kernel-devel kernel-headers libgomp make patch gcc glibc-headers glibc-devel dkms
# dnf install -y VirtualBox-6.1
# usermod -aG vboxusers developer
# /usr/lib/virtualbox/vboxdrv.sh setup  <= Fails


# https://releases.ansible.com/ansible-tower/setup-bundle/ansible-tower-setup-bundle-3.6.4-1.el8.tar.gz
TOWER_VER=3.6.4-1
OS=el8
EXT=.tar.gz

TOWER=ansible-tower-setup-bundle-${TOWER_VER}
TOWER_PKG=${TOWER}.${OS}${EXT}
TOWER_URL=https://releases.ansible.com/ansible-tower/setup-bundle/${TOWER_PKG}


# ===================================================================
# Note from RHEL Installation Notes:
# PackageKit can frequently interfere with the installation/update mechanism. 
# Consider disabling or removing PackageKit if installed prior to running the 
# setup process.
function StopPackageKit
{
    echo 'Stopping PackageKit'
    systemctl stop packagekit
}
# -------------------------------------------------------------------

# ===================================================================
#
function InstallToolsAndUpdate
{
    dnf -y install git
    dnf -y install wget
    dnf -y install rsync
    dnf -y update
}
# -------------------------------------------------------------------

function InstallEpel
{
    dnf -y install epel-release
    dnf makecache
}
# -------------------------------------------------------------------

# ===================================================================
# Ansible Tower uses PostgreSQL 10, which is an SCL package on RHEL 7 
# and an app stream on RHEL8. 
#
# Note that the Tower package includes a matching Ansible installation
#
function InstallAnsible
{
    # Install directly from repositories
    # dnf install ansible
    
    # Or an interesting alternative is to create an RPM
    git clone https://github.com/ansible/ansible.git
    cd ./ansible
    make rpm
    sudo rpm -Uvh ./rpm-build/ansible-*.noarch.rpm
        
    ansible --version
}
# -------------------------------------------------------------------

# ===================================================================
# https://manjaro.site/how-to-postgresql-10-on-centos-8/
#
function InstallPostgreSQL
{
    echo 'InstallPostgreSQL'

    # Lists postgresql modules available ([d] indicates the default value
    dnf module list postgresql

    # Install Version 10 explicitely
    dnf -y install @postgresql:10

    # The following would install the default version without specifying
    # dnf -y install postgresql

    # Install contrib package (may not be mandatory)
    dnf -y install postgresql-contrib

    # NOTE: The following are post install steps
    # postgresql-setup initdb
    #
    # systemctl start postgresql
    # systemctl enable postgresql
    #
    # su - postgres
    # psql
    # ALTER USER postgres WITH PASSWORD '12345';
    #
    # su
    # edit /var/lib/pgsql/data/postgresql.conf
    # 
    # Edit the value of listen_addresses = ‘localhost‘ to ‘*’ as follow:
    # 
    # - Connection Settings -
    #  listen_addresses = '*'          # what IP address(es) to listen on;
    # 
    # su
    # edit /var/lib/pgsql/data/pg_hba.conf
    # 
    # add the following line to the end of the file
    # 
    # host    all             all             0.0.0.0/0               md5
    # 
    # Restart PostgreSQL service
    # 
    # su
    # systemctl restart postgresql
    # 

}
# -------------------------------------------------------------------

# ===================================================================
#
function InstallTower
{
    mkdir ~/work
    pushd ~/work
    
    wget ${TOWER_URL}
    tar xvf ${TOWER_PKG}
    pushd ${TOWER}
    
    # Setup actions that must be performed before running setup.sh
    sed -i "s/admin_password=''/admin_password='holstein'/g" ./inventory
    sed -i "s/pg_password=''/pg_password='holstein'/g" ./inventory
    sed -i "s/rabbitmq_password=''/rabbitmq_password='holstein'/g" ./inventory
    
    ./setup.sh
    
    popd
    popd
    
}
# -------------------------------------------------------------------

# ===================================================================
#
function MyFunction
{
    echo 'Function sample'
}
# -------------------------------------------------------------------

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
StopPackageKit
InstallToolsAndUpdate

# InstallEpel         # <= Handled by Tower package
# InstallAnsible      # <= Included in Tower package
# InstallPostgreSQL   # <= Included in Tower package

InstallTower

