#!/bin/sh

##########################################################################
#            POST INSTALLATION CONFIGURATION REQUIREMENTS                #
##########################################################################

### For Apache ###########################################################
# Configuration notes
# Load SSL modules in /etc/httpd/conf/httpd.conf per examples below
# See: https://computingforgeeks.com/install-apache-with-ssl-http2-on-rhel-centos/
#

###  For Database - MariaDB
# Configuration notes
#
# Run: mysql_secure_installation - MUST run as root, sudo doesn't seem to work
#      mariadb_secure_installation
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

# To set or change MySQL password:
# mysql (starts mysql prompt)
# use mysql;
# update user setpassword=PASSWORD("<password>") where User='root';
# flush privileges;
# quit;

### For PHP ##############################################################

# Run: sudo vi /etc/php.ini

#      Make the following modifications (note also check to ensure these items are not commented)
#   max_execution_time = 300
#   upload_max_filesize = 100M
#   post_max_size = 128M
#   date.timezone = America/Chicago

# Run: sudo vi /etc/httpd/conf/httpd.conf

#      Add the following AddHandler line after LoadModule section 
#   # The following line enables PHP loading by Apache
#   AddHandler php-script .php 

# Restart Apache & PHP-FPM by running:

#    sudo systemctl restart php-fpm
#    sudo systemctl restart httpd

# AFTER TEST RUNNING PHP, REMOVE info.php 

### For PhpMyAdmin #######################################################
# See: https://computingforgeeks.com/install-and-configure-phpmyadmin-on-rhel-8/
#
# phpMyAdmin web interface should be available:
# http://<hostname>/phpmyadmin
# The login screen should display.
#
# Log in using your database credentials - use root password set with mysql-secure-installation
#

##########################################################################
##########################################################################
##########################################################################
#
# URL & Application definitions

# 20250707 - Modifying to:
#            NOT install WordPress
#            Minor updates to PHP installation 

PHP_MYADMIN_VER=5.2.2
PHP_MYADMIN_URL=https://files.phpmyadmin.net/phpMyAdmin/${PHP_MYADMIN_VER}/phpMyAdmin-${PHP_MYADMIN_VER}-english.tar.gz

##########################################################################
#
function PerformUpdate
{
    sudo dnf -y update
}
# ------------------------------------------------------------------------

##########################################################################
#
function InstallBasicPackages
{
    echo "Function: InstallBasicPackages starting"

    sudo dnf install -y git wget zip unzip curl

    # phpMyAdmin (and certbot) need to modify SELinux settings.
    # The following line is not specifically required, but will show you what package
    # is required to install semanage (for SELinux configuration).
    # It tells you that you will need policycoreutils-python-utils
    yum whatprovides semanage
    sudo dnf install -y policycoreutils-python-utils
    sudo dnf -y install setroubleshoot-server

    # From: https://docs.rockylinux.org/guides/security/generating_ssl_keys_lets_encrypt/
    # Install letsencrypt certbot
    sudo dnf -y install epel-release

    # Enable CRB to provide access to more development tools
    sudo dnf config-manager --set-enabled crb

    sudo dnf -y install certbot python3-certbot-apache

    echo "Function: InstallBasicPackages complete"
}

##########################################################################
# Install and setup Apache
# From: https://docs.rockylinux.org/books/web_services/021-web-servers-apache/
#
function InstallApache
{
    echo "Function: InstallApache starting"

    # Install apache & SSL support, NOTE mod_md is REQUIRED for letsenctypt 
    sudo dnf install -y httpd mod_ssl mod_md openssl nmap

    # Start httpd & check status
    sudo systemctl enable --now httpd
    sudo systemctl is-enabled httpd

    # Create subdirectories for Multi Site support
    # The actual configuration files will be in /etc/httpd/sites-available but 
    # you will symlink to them in /etc/httpd/sites-enabled.
    sudo mkdir --parents /etc/httpd/sites-available /etc/httpd/sites-enabled
    sudo mkdir /var/www/sub-domains/

    # Include 'sites-enabled' in Apache's main configuration file
    sudo echo '' >> /etc/httpd/conf/httpd.conf
    sudo echo 'Include /etc/httpd/sites-enabled' >> /etc/httpd/conf/httpd.conf
    sudo echo '' >> /etc/httpd/conf/httpd.conf

    echo "Function: InstallApache complete"
}
# ------------------------------------------------------------------------

##########################################################################
# Install and setup MariaDB
# From: https://docs.rockylinux.org/guides/database/database_mariadb-server/
#
function InstallDataBase
{
    echo "Function: InstallDataBase starting"

    sudo dnf install -y mariadb-server mariadb

    # The following displays version information for MariaDB
    rpm -qi mariadb-server

    systemctl enable --now mariadb

    echo "Function: InstallDataBase complete"
}
# ------------------------------------------------------------------------

##########################################################################
# Install PHP
# From: https://docs.rockylinux.org/guides/web/php/
#       Use Remi repository to get PHP 8.4 (8.5 still in beta)
#
function InstallPhp
{
    echo "Function: InstallPhp starting"

    # Install Remi repositories
    sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-10.rpm
    sudo dnf -y config-manager --set-enabled remi
    sudo dnf -y module enable php:remi-8.4

    # PHP Installation, and extra packages
    sudo dnf install -y php 
    sudo dnf install -y php-cli php-fpm php-curl php-mysqlnd php-gd php-opcache php-zip \
        php-common php-bcmath php-imagick php-xmlrpc php-json php-readline \
        php-memcached php-redis php-mbstring php-apcu php-xml php-dom php-redis \
        php-memcached php-memcache php-pear

    sudo dnf -y install php-{cgi,gettext,imap,pdo,mysqli,odbc}

    # Install development & debugging tools
    sudo dnf -y install php-devel php-xdebug php-pcov

    # This group supports WordPress, Joomla & Drupal 
    sudo dnf -y install php-ldap php-soap curl-devel

    # Install connector & start PHP connection to Apache
    sudo dnf -y install php-fpm
    sudo systemctl enable --now php-fpm
    sudo systemctl status php-fpm

    # Show php version
    php --version

    # Show active PHP modules
    php --modules

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

    # Download the version specified above, then extract and relocate
    wget ${PHP_MYADMIN_URL}
    tar xvf phpMyAdmin-${PHP_MYADMIN_VER}-english.tar.gz
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
function ConfigureFirewall
{
    echo "Function: ConfigureFirewall starting"

    # Open firewall for http (consider removing this one after https/ssl is configured)
    firewall-cmd --permanent --zone=public --add-service=http
    firewall-cmd --permanent --zone=public --add-service=https

    # firewall-cmd --permanent --add-port=80/tcp
    # firewall-cmd --permanent --add-port=443/tcp

    firewall-cmd --reload

    # Show firewall settings
    firewall-cmd --list-services --zone=public

    echo "Function: ConfigureFirewall complete"
}
# ------------------------------------------------------------------------

##########################################################################
# Create a default landing page for Apache
# NOTE that this page will be the default when other multi-site pages fail.
#
function CreateDefaultIndexHtml
{
    echo "Function: CreateDefaultIndexHtml starting"

    # Add the subdirectories needed for default site (and its associated keys ??)
    sudo mkdir --parents /var/www/sub-domains/00-default/html
    # sudo mkdir --parents /var/www/sub-domains/00-default/ssl/{ssl.key,ssl.crt,ssl.csr}

    # Make a simple default landing page in the directory created above
cat << EOF > /var/www/sub-domains/00-default/html/index.html
<html>
  <head>
    <title>Access Forbidden</title>
  </head>

  <body>
    <h2>Access Permission Denied</h2>
  </body>

</html>
EOF

    # Create a multi site configuration file for default page
cat << EOF > /etc/httpd/sites-available/00-default
<VirtualHost *:80>
        ServerName 00-default
        ServerAdmin steve.gomez.sg79@gmail.com
        DocumentRoot /var/www/sub-domains/00-default/html/
        CustomLog "/var/log/httpd/00-default-access_log" combined
        ErrorLog  "/var/log/httpd/00-default-error_log"
#        Redirect / https://00-default/
</VirtualHost>
#<VirtualHost *:443>
#        ServerName 00-default
#        ServerAdmin steve.gomez.sg79@gmail.com
#        DocumentRoot /var/www/sub-domains/00-default/html/
#        DirectoryIndex index.php index.htm index.html
#        Alias /icons/ /var/www/icons/
#
#        TBD
#
#</VirtualHost>
EOF

    # This line makes this site live by making it visible in sites-enabled
    ln -s /etc/httpd/sites-available/00-default /etc/httpd/sites-enabled/

    echo "Function: CreateDefaultIndexHtml complete"
}
# ------------------------------------------------------------------------



##########################################################################
function InstallApacheCertificates
{
    echo "Function: InstallApacheCertificates starting"

    exit

    # From: https://docs.rockylinux.org/guides/security/generating_ssl_keys_lets_encrypt/

    # The following step requires user interaction to enter domain information
    certbot certonly --apache

    # From: https://eff-certbot.readthedocs.io/en/stable/using.html#apache
    #       Since httpd does NOT run as root, the following is needed:
    # chmod 0755 /etc/letsencrypt/{live,archive}
    # chgrp apache /etc/letsencrypt/live/steven-gomez.com/*.pem
    # chmod 0640 /etc/letsencrypt/live/steven-gomez.com/*.pem

    # Need to experiment with which of these semanage commands are best
    semanage fcontext -a -t httpd_cert_t "/etc/letsencrypt(/.*)?"
    restorecon -Rv /etc/letsencrypt

    # The following directories are likely bogus!
    semanage fcontext -a -t httpd_sys_content_t "/srv/example.com(/.*)?"
    restorecon -Rv /srv/example.com/

    # From web example (not sure if applies to multi-site): 
    # https://unix.stackexchange.com/questions/358089/apache-ssl-server-cert-does-not-include-id-which-matches-server-name
    sudo chcon --recursive system_u:object_r:httpd_sys_content_t:s0 /etc/letsencrypt/

    # These didn't change anything; issues were probably selinux config related
    #usermod -a -G certbot apache
    #chmod 750 /etc/letsencrypt/archive /etc/letsencrypt/live
    #chmod 640 /etc/letsencrypt/archive/*/*.pem

    # The following tests automatic renewal
    certbot renew --dry-run

    echo "Function: InstallApacheCertificates complete"
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
    echo "    INSTALL        Installs required applications - MUST BE RUN FIRST"
    echo "    ADD_CERTS      Adds third party cerficates; MUST RUN AS ROOT."
    echo ""
    echo "Usage: $0 INSTALL || ADD_CERTS || ADD_MULTISITE"
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
    echo "========================================================================================="
    echo "=================== Installing LAMP applications ========================================"
    echo "========================================================================================="

    PerformUpdate
    InstallBasicPackages

    ConfigureFirewall
    InstallApache

    exit

    CreateDefaultIndexHtml

    # Web Service (Apache httpd) should now be running
    # http://<server-name> will show 'Access Forbidden' page.

    InstallDataBase
    InstallPhp

    InstallPhpMyAdmin
fi

#  Install the certificates
if [ $ACTION_TYPE = "ADD_CERTS" ]
then
    echo "========================================================================================="
    echo "=================== Setting up Certificates ============================================="
    echo "========================================================================================="

    InstallApacheCertificates

fi

