#!/bin/sh

#
# Significant contents of this script are courtesy of:
# https://www.howtoforge.com/tutorial/centos-lamp-server-apache-mysql-php/
# 

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
#     SELECT VERSION():     <== Shows the MariaDB version
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
    dnf install -y nano

    # From: https://www.itsupportwale.com/blog/how-to-install-php-7-3-on-centos-8/
    # Install repositories for access to latest PHP
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    
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

    dnf -y install -y @httpd

    # systemctl start httpd
    systemctl enable --now httpd.service

    # Make a stub HTML page
    echo "<h1>Hello Internet World, this is our Apache web server.</h1>" > /var/www/html/index.html

    # The following shows the status of httpd.service
    systemctl is-enabled httpd.service
    
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
    export VER="4.9.1"
    
    # Download the version specified above, then extract and relocate
    curl -o phpMyAdmin-${VER}-english.tar.gz  https://files.phpmyadmin.net/phpMyAdmin/${VER}/phpMyAdmin-${VER}-english.tar.gz
    tar xvf phpMyAdmin-${VER}-english.tar.gz
    rm phpMyAdmin-*.tar.gz
    mv phpMyAdmin-* /usr/share/phpmyadmin
    
    # Create directory structure needed by phpMyAdmin
    mkdir -p /var/lib/phpmyadmin/tmp
    chown -R apache:apache /var/lib/phpmyadmin
    
    mkdir /etc/phpmyadmin/
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
    
    systemctl restart httpd
    
    # Set SELinux to allow access to phpMyAdmin page
    semanage fcontext -a -t httpd_sys_content_t "/usr/share/phpmyadmin(/.*)?"
    restorecon -Rv /usr/share/phpmyadmin
    
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

# ====================================================================================
# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================

systemctl stop packagekit

PerformUpdate
InstallBasicPackages

ConfigureFirewall
InstallPhp
InstallDataBase
InstallApache
InstallPhpMyAdmin

InstallWordPress

