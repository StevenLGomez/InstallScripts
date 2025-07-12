#!/bin/sh

##########################################################################
#            POST INSTALLATION CONFIGURATION REQUIREMENTS                #
##########################################################################

### For Apache ###########################################################
# Configuration notes
# Load SSL modules in /etc/httpd/conf/httpd.conf per examples below
# See: https://computingforgeeks.com/install-apache-with-ssl-http2-on-rhel-centos/
#
# systemctl restart httpd.service

###  For Database - MariaDB
# Configuration notes
#
# Run: mysql_secure_installation - MUST run as root, sudo doesn't seem to work
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

##
## Then restart Apache again with:
## systemctl restart httpd.service
##
## Also set up Web Server Authentication Gate and .htaccess file per:
## https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-with-apache-on-a-centos-7-server

### For WordPress ########################################################
# See: https://wordpress.org
#
# Create the necessary database entries using:
#     mysql -u root -p                 <<== Use root password entered in mysql_secure_installation
#     CREATE DATABASE wordpress_db;
#     GRANT ALL PRIVILEGES ON wordpress_db.* TO wp_user@localhost IDENTIFIED BY 'secret-pwd';
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
# SELinux Alerts - On Rocky 9 needed to update security settings
#
# * Allow php-fpm to have write access on the wordpress directory *
# semanage fcontext -a -t httpd_sys_rw_content_t 'wordpress'
# restorecon -v 'wordpress'
#
# * If you want to allow httpd to 'unified' *
# setsebool -P httpd_unified 1
#
# * If you believe that php-fpm should be allowd write access on the wordpress directory by default *
# !! You should report this as a bug !!
# ausearch -c 'php-fpm' --raw | audit2allow -M my-phpfpm
# semodule -X 300 -i my-phpfpm.pp
#


##########################################################################
##########################################################################
##########################################################################
#
# URL & Application definitions

# 20250707 - Modifying to:
#            NOT install WordPress
#            Minor updates to PHP installation 

# Download (wget) the latest version directly from the wordpress.org
WORDPRESS_PKG=latest.tar.gz
WORDPRESS_URL=https://wordpress.org/${WORDPRESS_PKG}

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

    # From: https://docs.rockylinux.org/guides/security/generating_ssl_keys_lets_encrypt/
    # Install letsencrypt certbot
    sudo dnf -y install epel-release
    sudo dnf -y install certbot python3-certbot-apache

    echo "Function: InstallBasicPackages complete"
}

##########################################################################
# Install and setup Apache
#
function InstallApache
{
    echo "Function: InstallApache starting"

    # Install apache & SSL support 
    sudo dnf install -y httpd mod_ssl openssl

    # systemctl start httpd
    sudo systemctl enable --now httpd

    # The following shows the status of httpd.service
    sudo systemctl is-enabled httpd

    echo "Function: InstallApache complete"
}
# ------------------------------------------------------------------------

##########################################################################
# Install and setup MariaDB
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
# From: (DEPRECATED) https://linuxcapable.com/how-to-install-php-on-rocky-linux/
#
function InstallPhp
{
    echo "Function: InstallPhp starting"

    # https://docs.rockylinux.org/guides/web/apache-sites-enabled/
    # Per Rocky docs noted above, it is no longer necessary to pull from Fedora.
    # You can just install php. 

    # Enable CRB to provide access to more development tools
    # sudo dnf config-manager --set-enabled crb

    # Install EPEL repositories
    # sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    #     https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm

    # sudo dnf install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm
    # sudo dnf module enable php:remi-8.4 -y

    # Apache (httpd) PHP Installation, and extra packages
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

    # Show php version
    php --version

    # Show active PHP modules
    php --modules

    # Create dummy php test page
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
    chown apache:apache /var/www/html/info.php

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

    # phpMyAdmin needs to modify SELinux settings
    # The following line is not specifically required, but will show you what package
    # is required to install semanage (for SELinux configuration).
    # It tells you that you will need policycoreutils-python-utils
    yum whatprovides semanage
    sudo dnf install -y policycoreutils-python-utils

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
#
function InstallWordPress
{
    echo "Function: InstallWordPress starting"

    # Download the installation package directly from the Wordpress site.
    wget --no-check-certificate ${WORDPRESS_URL} --directory-prefix /var/www/html

    cd /var/www/html
    tar -xvf ${WORDPRESS_PKG}

    chown -R apache:apache /var/www/html/wordpress  

    # Remove the original file after extracting
    rm -f ${WORDPRESS_PKG}
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
function CreateDefaultIndexHtml
{
    echo "Function: CreateDefaultLandingPage starting"

    echo '' > /var/www/html/index.html          
    echo '<html>' >> /var/www/html/index.html          
    echo '  <head>' >> /var/www/html/index.html          
    echo '    <title>Apache Server Test Page</title>' >> /var/www/html/index.html          
    echo '  </head>' >> /var/www/html/index.html          
    echo '' >> /var/www/html/index.html          
    echo '  <body>' >> /var/www/html/index.html          
    echo '    <h1>LAMP Stack is alive & well on Rocky Linux 9</h1>' >> /var/www/html/index.html          
    echo '  </body>' >> /var/www/html/index.html          
    echo '' >> /var/www/html/index.html          
    echo '</html>' >> /var/www/html/index.html          
    echo '' >> /var/www/html/index.html          

    chown apache:apache /var/www/html/index.html

    echo "Function: CreateDefaultLandingPage complete"
}
# ------------------------------------------------------------------------


##########################################################################
# From: https://docs.rockylinux.org/guides/web/apache-sites-enabled/
#
function ConfigureMultiSite
{
    echo "Function: ConfigureMultiSite starting"

    # The actual configuration files will be in /etc/httpd/sites-available but 
    # you will symlink to them in /etc/httpd/sites-enabled.
    # This allows a broken site to be unlinked for repair without taking down
    # the rest.
    sudo mkdir --parents /etc/httpd/sites-available /etc/httpd/sites-enabled
    sudo mkdir /var/www/sub-domains/

    # Update Apache configuration, Include the sites-enabled path
    sudo echo '' >> /etc/httpd/conf/httpd.conf
    sudo echo 'Include /etc/httpd/sites-enabled' >> /etc/httpd/conf/httpd.conf
    sudo echo '' >> /etc/httpd/conf/httpd.conf

    # Add the subdirectories needed for your supported site and its associated keys
    sudo mkdir --parents /var/www/sub-domains/steven-gomez.com/html
    sudo mkdir --parents /var/www/sub-domains/steven-gomez.com/ssl/{ssl.key,ssl.crt,ssl.csr}

    # Create the multi site configuration file, modify and add <VirtualHost>s as needed:
cat << EOF > /etc/httpd/sites-available/steven-gomez.com
<VirtualHost *:80>
        ServerName steven-gomez.com
        ServerAdmin steve.gomez.sg79@gmail.com
        Redirect / https://steven-gomez.com/
</VirtualHost>
<VirtualHost *:443>
        ServerName steven-gomez.com
        ServerAdmin steve.gomez.sg79@gmail.com
        DocumentRoot /var/www/sub-domains/steven-gomez.com/html/
        DirectoryIndex index.php index.html
        Alias /icons/ /var/www/icons/
        # ScriptAlias /cgi-bin/ /var/www/sub-domains/steven-gomez.com/cgi-bin/

        CustomLog "/var/log/httpd/steven-gomez.com-access_log" combined
        ErrorLog  "/var/log/httpd/steven-gomez.com-error_log"

        SSLEngine on
        SSLProtocol all -SSLv2 -SSLv3 -TLSv1
        SSLHonorCipherOrder on

        SSLCertificateFile /var/www/sub-domains/steven-gomez.com/ssl/ssl.crt/steven-gomez.com.crt
        SSLCertificateKeyFile /var/www/sub-domains/steven-gomez.com/ssl/ssl.key/steven-gomez.com.key

        <Directory /var/www/sub-domains/steven-gomez.com/html>
                Options -ExecCGI -Indexes
                AllowOverride None

                Order deny,allow
                Deny from all
                Allow from all

                Satisfy all
        </Directory>
</VirtualHost>
EOF

    # Make a test landing page
cat << EOF > /var/www/sub-domains/steven-gomez.com/html/index.html
<html>
  <head>
    <title>Apache Server Test Page</title>
  </head>

  <body>
    <h1>Web site on Rocky Linux 9</h1>
	steven-gomez.com
  </body>

</html>
EOF
    # Change ownership of the file just created
    chown apache:apache /var/www/sub-domains/steven-gomez.com/html/index.html

    # Create dummy php test page in this sub-domain
    echo "<?php phpinfo(); ?>" > /var/www/sub-domains/steven-gomez.com/html/info.php
    chown apache:apache /var/www/sub-domains/steven-gomez.com/html/info.php

    echo "Function: ConfigureMultiSite complete"
}
# ------------------------------------------------------------------------

##########################################################################
function InstallApacheCertificates
{
    echo "Function: InstallApacheCertificates starting"

    # From: https://docs.rockylinux.org/guides/security/generating_ssl_keys_lets_encrypt/

    # The following step requires user interaction to enter domain information
    certbot certonly --apache

    # The following tests automatic renewal
    certbot renew --dry-run

    echo "Function: InstallApacheCertificates complete"
}
# ------------------------------------------------------------------------

##########################################################################
function InstallNginxCertificates
{
    echo "Function: InstallNginxCertificates starting"

    # From: https://docs.rockylinux.org/guides/security/generating_ssl_keys_lets_encrypt/

    echo "Implementation pending..... , but expected to be similar to InstallApacheCertificates()"

    echo "Function: InstallNginxCertificates complete"
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
    echo "    ADD_MULTISITE  Configures support for multiple web sites - RUN SECOND"
    echo "    ADD_CERTS      Adds third party cerficates; requires user interaction."
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

if [ "$1" = "ADD_MULTISITE" ]
then
    echo "ADD_MULTISITE - Adding multi-site support"
    ACTION_TYPE=ADD_MULTISITE
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

    InstallApache
    ConfigureFirewall
    CreateDefaultIndexHtml
    # Web Service (Apache httpd) should now be running

    InstallDataBase
    InstallPhp

    InstallPhpMyAdmin

    # InstallWordPress
fi

#  Add Multi Site Support
if [ $ACTION_TYPE = "ADD_MULTISITE" ]
then
    echo "========================================================================================="
    echo "=================== Adding Multi Site Support ==========================================="
    echo "========================================================================================="

    ConfigureMultiSite

fi

#  Install the certificates
if [ $ACTION_TYPE = "ADD_CERTS" ]
then
    echo "========================================================================================="
    echo "=================== Setting up Certificates ============================================="
    echo "========================================================================================="

    InstallApacheCertificates

fi

