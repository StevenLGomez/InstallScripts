#!/bin/bash

# Redmine installation script based on (with liberties for use on CentOS 8
# https://redmine.org/projects/redmine/wiki/Install_Redmine_346_on_Centos_75

# Definitions to define URLs for downloading Applications
APPLICATION_SERVER_URL=http://10.1.1.26/Applications

REDMINE_VER=4.1.1
REDMINE_SRC=redmine-${REDMINE_VER}
REDMINE_PKG=${REDMINE_SRC}.tar.gz
REDMINE_URL=${APPLICATION_SERVER_URL}/Redmine/${REDMINE_PKG}


##########################################################################
# Normal update...
function PerformUpdate
{
    dnf -y update
}
# ------------------------------------------------------------------------

##########################################################################
# 
function InstallBasicApplications
{
    dnf -y install git
    dnf -y install wget
}
# ------------------------------------------------------------------------

##########################################################################
# Install and setup MariaDB
#
function InstallDataBase
{
    echo "Function: InstallDataBase starting"

    dnf module install -y mariadb

    # The following displays version information for MariaDB
    rpm -qi mariadb-server
    
    systemctl enable --now mariadb

    echo "Function: InstallDataBase complete"
}    
# ------------------------------------------------------------------------

##########################################################################
# Install and setup Ruby
#
function InstallRuby
{
    echo "Function: InstallRuby starting"
    
    # Need to enable Power Tools repository for libyaml-devel and iconv-devel
    sed --in-place 's/enabled=0/enabled=1/' /etc/yum.repos.d/CentOS-Linux-PowerTools.repo
    
    rpm -ivh https://forensics.cert.org/centos/cert/8/x86_64/libiconv-devel-1.15-1.el8.x86_64.rpm

    yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel \
        libyaml-devel libffi-devel openssl-devel make \
        bzip2 autoconf automake libtool bison sqlite-devel

    curl -sSL https://rvm.io/mpapis.asc | gpg --import -  
    curl -L https://get.rvm.io | bash
    
    source /etc/profile.d/rvm.sh
    rvm reload
    rvm requirements run
    rvm install 2.4
    rvm list
    ruby --version

    echo "Function: InstallRuby complete"
}    
# ------------------------------------------------------------------------


##########################################################################
# Install PHP 
#
function InstallPhp
{
    echo "Function: InstallPhp starting"

    dnf module install -y php:remi-7.4
    
    # Create dummy php test page
    echo "<?php phpinfo(); ?>" >> /var/www/html/info.php

    # Add other PHP modules as needed (desired?) - yum search php
    yum -y install php-mysqlnd php-pdo php-pecl-zip php-common php-fpm php-cli php-bcmath
    
    # This group supports phpMyAdmin
    yum -y install php-json php-mbstring 

    # This group supports WordPress, Joomla & Drupal
    yum -y install php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-soap curl curl-devel

    echo "Function: InstallPhp complete"
}
# ------------------------------------------------------------------------


##########################################################################
function InstallRedmine
{
    pushd /home/developer

    # Use wget to pull the Python package
    wget ${REDMINE_URL}

    # Unpack, configure and make Python 3.8
    tar xvfz ${REDMINE_PKG}

    export REDMINE_PATH=/home/developer/${REDMINE_SRC}
    cd ${REDMINE_PATH}
    cp config/database.yml.example config/database.yml
    
    chown -R developer:developer ${REDMINE_PATH}
    
    # Remove all instances of package files
    rm -f *.tar.gz*

    popd
}
# ------------------------------------------------------------------------

##########################################################################
function InstallGemsRepository
{


    cd $REDMINE
    gem install bundler
    bundle install --without development test
    bundle exec rake generate_secret_token
    RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data
 
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
InstallBasicApplications

# InstallDataBase
# InstallRuby

# InstallPhp # May not be needed

# InstallRedmine
InstallGemsRepository



