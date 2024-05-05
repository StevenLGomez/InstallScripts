#!/bin/sh

##########################################################################
#            POST INSTALLATION CONFIGURATION REQUIREMENTS                #
##########################################################################

### For Apache ###########################################################
# Configuration notes
# Load SSL modules in /etc/httpd/conf/httpd.conf per examples below
# See: https://computingforgeeks.com/install-apache-with-ssl-http2-on-rhel-centos/

# systemctl restart httpd.service

###  For Database - MariaDB
# Configuration notes
# See: https://computingforgeeks.com/how-to-install-mariadb-database-server-on-rhel-8/
#
# Run: mysql_secure_installation
#
#      * If root password was not previously set, press enter for option to create it
#      * Set root password               Temporarily use C...S...00
#      * Remove anonymous users?         Y
#      * Disallow root login remotely?   Y
#      * Remote test database .... ?     Y
#      * Reload privilege tables now?    Y
#
# You can then start mysql using:
#     mysql -u root -p
#
#     SELECT VERSION();     <== Shows the MariaDB version
#
#     exit;                 <== Exits & returns to the shell
#
# To set or change MySQL password:
# mysql (starts mysql prompt)
# use mysql;
# update user setpassword=PASSWORD("<password>") where User='root';
# flush privileges;
# quit;



### For PhpMyAdmin #######################################################
# See: https://computingforgeeks.com/install-and-configure-phpmyadmin-on-rhel-8/
#
# phpMyAdmin web interface should be available:
# http://<hostname>/phpmyadmin
# The login screen should display.
#
# Log in using your database credentials - use root password set with mysql-secure-installation
#
# TBD OLD notes follow
# Edit /etc/httpd/conf.d/phpMyAdmin.conf
# Comment all instances of Require ip 127.0.0.1
# Comment all instances of Require ip ::1
# Comment all instances of Allow from 127.0.0.1
# Comment all instances of Allow from ::1
# For all of the items commented above, add the line:
# Require all granted

# Other notes (TBD - investigate their need)
# The following is still a work in progress....

## Create user that will have permission to upload site content
## NOTE, the following will give a (desired) warning about the directory
## already existing
## Must also set password using passwd webdeveloper
# adduser -d /var/www/html -G apache webdeveloper
# chgrp -R apache /var/www/html
# sudo chmod -R g+w /var/www/html
# sudo chmod g+s /var/www/html

##
## Then restart Apache again with:
## systemctl restart httpd.service
##
## Also set up Web Server Authentication Gate and .htaccess file per:
## https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-with-apache-on-a-centos-7-server


### For WordPress ########################################################
# See: https://wordpress.org
#
# The InstallWordPress function sets the DB_NAME, DB_USER and DB_PASSWORD
# to 'wp_db, 'wp_user' and 'wp_secret_pwd' respectively.
#
# NOTE that these values must be created in the database before
#      you can expect WordPress to function properly.
#
#      ALSO, if these values are changed here, the InstallWordPress
#            function must be changed accordingly
#
# From: http://www.daniloaz.com/en/how-to-create-a-user-in-mysql-mariadb-and-grant-permissions-on-a-specific-database/
#       Site above includes a script option, might be worth looking at...
#       But leaves you hanging a bit on some of the syntax, steps below work though...
#
# Create the necessary database entries using:
#     mysql -u root -p            <<== Will require root password
#     CREATE DATABASE `wordpress`;    <<== NOTE those are backticks, not single quotes
#     CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'wp_secret_pwd';
#     GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';
#     FLUSH PRIVILEGES;
#
#     # To test the above:
#     SHOW GRANTS FOR wp_user@localhost;
#
#     # To back out mistakes that may have been made...
#     DROP USER wp_user@localhost
#     DROP DATABASE wp_db;
#
#     exit;          <<== To return to shell
#

##########################################################################
#
# URL & Application definitions
#

# Download (wget) the latest version directly from the wordpress.org
# !! Proceed with caution - wget is not always reliable inside bioMerieux
WORDPRESS=latest.tar.gz
WORDPRESS_URL=https://wordpress.org/${WORDPRESS}


##########################################################################
#
function PerformUpdate
{
    dnf -y update
}
# ------------------------------------------------------------------------

##########################################################################
#
function InstallBasicPackages
{
    echo "Function: InstallBasicPackages starting"

    dnf install -y subversion
    dnf install -y git
    dnf install -y wget
    dnf install -y unzip

    # From: https://www.itsupportwale.com/blog/how-to-install-php-7-3-on-centos-8/
    # Install repositories for access to latest PHP
#    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
#    dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm

    # phpMyAdmin needs to modify SELinux settings
    # The following line is not specifically required, but will show you what package
    # is required to install semanage (for SELinux configuration).
    # It tells you that you will need policycoreutils-python-utils
    yum whatprovides semanage
    dnf install -y policycoreutils-python-utils

    echo "Function: InstallBasicPackages complete"
}

##########################################################################
# Install and setup Apache
#
function InstallApache
{
    echo "Function: InstallApache starting"

    # The following are required to support SSL
    dnf install -y mod_ssl openssl

    dnf -y install -y httpd

    # systemctl start httpd
    systemctl enable --now httpd

    # The following shows the status of httpd.service
    systemctl is-enabled httpd

    echo "Function: InstallApache complete"
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
# Install PHP
#
function InstallPhp
{
    echo "Function: InstallPhp starting"

    dnf -y install epel-release
    dnf -y install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm
    dnf -y module list php

    dnf -y module reset php
    dnf -y module enable php:remi-8.0

    dnf -y install php php-cli php-curl php-mysqlnd php-gd php-opcache php-zip php-intl

    php -v

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
# Install phpMyAdmin - See associated markdown document for setup informaiton
# Should be able to access phpMyAdmin using http://<server>/phpMyAdmin
# (After access permissions are set)
#
# www.phpmyadmin.net/home_page/index.php
# Access on your server using: https://<dbhost>:8080/phpmyadmin
#
function InstallPhpMyAdmin
{
    echo "Function: InstallPhpMyAdmin starting"

    yum -y install php-mysqlnd

    # Declare the PhpMyAdmin version desired
    export VER="5.2.0"

    # Download the version specified above, then extract and relocate
    #curl -o phpMyAdmin-${VER}-english.tar.gz  https://files.phpmyadmin.net/phpMyAdmin/${VER}/phpMyAdmin-${VER}-english.tar.gz
    wget https://files.phpmyadmin.net/phpMyAdmin/${VER}/phpMyAdmin-${VER}-english.tar.gz
    tar xvf phpMyAdmin-${VER}-english.tar.gz
    rm phpMyAdmin-*.tar.gz
    mv phpMyAdmin-* /usr/share/phpmyadmin

    # Create directory structure and permissions needed by phpMyAdmin
    mkdir -p /usr/share/phpmyadmin/tmp
    chown -R apache:apache /usr/share/phpmyadmin
    chmod 777 /usr/share/phpmyadmin/tmp

    #mkdir /etc/phpmyadmin/
    cp /usr/share/phpmyadmin/config.sample.inc.php  /usr/share/phpmyadmin/config.inc.php

    # Edit /usr/share/phpmyadmin/config.inc.php
    # Set a secret passphrase - NOTE must be 32 chars long
    # $cfg['blowfish_secret'] = 'H2OxcGXxflSd8JwrwVlh6KW6s2rER63i';
    sed -i "s/\$cfg\['blowfish_secret'\] = ''/\$cfg\['blowfish_secret'\] = 'H2OxcGXxflSd8JwrwVlh6KW6s2rER63i'/g" /usr/share/phpmyadmin/config.inc.php

    # Configure the Temp directory to use /var/lib/phpmyadmin/tmp (created above)
    # Add the following line after the SaveDir entry
    # $cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';
    sed -i "/SaveDir/ a \$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';" /usr/share/phpmyadmin/config.inc.php

    # Create   /etc/httpd/conf.d/phpmyadmin.conf   with the following contents:
    echo '# Apache configuration for phpMyAdmin' > /etc/httpd/conf.d/phpmyadmin.conf
    echo 'Alias /phpMyAdmin /usr/share/phpmyadmin/' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo 'Alias /phpmyadmin /usr/share/phpmyadmin/' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '<Directory /usr/share/phpmyadmin/>' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '    AddDefaultCharset UTF-8' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '    <IfModule mod_authz_core.c>' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '        # Apache 2.4' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '        Require all granted' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '    </IfModule>' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '    <IfModule !mod_authz_core.c>' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '        # Apache 2.2' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '        Order Deny,Allow' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '        Deny from All' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '        Allow from 127.0.0.1' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '        Allow from ::1' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '    </IfModule>' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '</Directory>' >> /etc/httpd/conf.d/phpmyadmin.conf
    echo '' >> /etc/httpd/conf.d/phpmyadmin.conf

    # Validate Apache configuration - must report 'Syntax OK'
    apachectl configtest

    # Set SELinux to allow access to phpMyAdmin page
    chcon -Rv --type=httpd_sys_content_t /usr/share/phpmyadmin/*

    systemctl restart httpd

    echo "Function: InstallPhpMyAdmin complete"
}
# ------------------------------------------------------------------------

##########################################################################
#
function InstallWordPress
{
    echo "Function: InstallWordPress starting"

    wget --no-check-certificate ${WORDPRESS_URL} --directory-prefix /var/www/html
    cd /var/www/html
    tar -xvf ${WORDPRESS}

    # Remove the original file after extracting
    rm -f ${WORDPRESS}
    cd

# After the script has finished, use the WEB installer to complete installation.
# Seems appropriate because of the KEYs & SALTs.
#
    echo "Function: InstallWordPress complete"
}
# ------------------------------------------------------------------------

##########################################################################
function ConfigureFirewall
{
    echo "Function: ConfigureFirewall starting"

    # Open firewall for http (consider removing this one after https/ssl is configured)
    firewall-cmd --permanent --zone=public --add-service=http

    # Open firewall for https
    firewall-cmd --permanent --zone=public --add-service=https

    firewall-cmd --reload

    echo "Function: ConfigureFirewall complete"
}
# ------------------------------------------------------------------------

##########################################################################
function CreateDefaultHttpLandingPage
{
    echo "Function: CreateDefaultLandingPage starting"


    echo "Function: CreateDefaultLandingPage complete"
}
# ------------------------------------------------------------------------


##########################################################################
function InstallCertificates
{
    echo "Function: InstallCertificates starting"

    # Install snapd - from https://snapcraft.io/docs/installing-snap-on-rocky
    dnf -y install snapd
    systemctl enable --now snapd.socket

    # Create 'classic' link for snap
    ln -s /var/lib/snapd/snap /snap

    # Poorly documented, but this step is needed to create 'seed'
    systemctl status snapd.seeded.service

    # Install certbot - from https://certbot.eff.org/instructions?ws=apache&os=centosrhel8
    snap install core; snap refresh core

    # Check for and remove old version of certbot
    dnf -y remove certbot

    # Install new certbot
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot

    # The following step requires user interaction to enter domain information
    certbot --apache

    # The following tests automatic renewal
    certbot renew --dry-run

    echo "Function: InstallCertificates complete"
}
# ------------------------------------------------------------------------

# ====================================================================================
# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================

# Require one parameter
# $1 = Option String
#
# Supported options defined in if statement below
#

if [ -z "$1" ]
then
    echo "ERROR: Missing parameter - must specify INSTALL or ADD_CERTS node"
    echo ""
    echo "Supported Options:"
    echo "    INSTALL      Installs required applications - MUST BE RUN BEFORE ADD_CERTS"
    echo "    ADD_CERTS    Adds third party cerficates; requires user interaction."
    echo ""
    echo "Usage: $0 INSTALL || ADD_CERTS"
    exit
fi

# Echo the valid command line entry
echo $0 $1

if [ "$1" = "INSTALL" ]
then
    echo "INSTALL - Installing required applications"
    ACTION_TYPE="INSTALL"
fi

if [ "$1" = "ADD_CERTS" ]
then
    echo "ADD_CERTS - Adding third party certificates"
    ACTION_TYPE=ADD_CERTS
fi

echo "Applying ACTION_TYPE:  ${ACTION_TYPE}"

#  Start the installation procedure....
if [ $ACTION_TYPE = "INSTALL" ]
then
    echo "=============================================================================================="
    echo "======================== Installing LAMP applications ========================================"
    echo "=============================================================================================="

#    PerformUpdate
#    InstallBasicPackages

#    InstallApache
#    ConfigureFirewall
    # Web Service (Apache httpd) should now be running

    InstallDataBase
    exit

    InstallPhp

    InstallPhpMyAdmin

    InstallWordPress
fi

#  Install the certificates
if [ $ACTION_TYPE = "ADD_CERTS" ]
then
    echo "=============================================================================================="
    echo "======================== Setting up Certificates ============================================="
    echo "=============================================================================================="

    InstallCertificates

fi

