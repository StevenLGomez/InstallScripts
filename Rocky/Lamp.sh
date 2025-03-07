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



### For configuring VirtualHosts #########################################
# After all basic sites have been created (or at least stubs in directories)
#
# Method 1 ---------------------------------------------------------------
#
# Create some stub directories for experimentation
#    cd /var/www/html
#    sudo mkdir site1
#    sudo mkdir site2
#    sudo chown apache:apache -R site1
#    sudo chown apache:apache -R site2
#
# Create sites-available & sites-enabled directories
#    cd /etc/httpd
#    sudo mkdir sites-available
#    sudo mkdir sites-enabled
#
#    sudo vi /etc/httpd/conf/httpd.conf <== At end of this file, add:
#    IncludeOptional sites-enabled/*.conf
#
#    cd sites-available
#    sudo vi site1.com.conf
#
#    <VirtualHost *:80>
#
#        ServerName www.site1.com
#        ServerAlias site1.com
#        DocumentRoot /var/www/html/site1/
#        ErrorLog /var/www/html/site1/error.log
#        CustomLog /var/www/html/site1/requests.log combined
#    </VirtualHost>
#
#    sudo cp site1.com.conf site2.com.conf
#    sudo vi site2.com.conf (then change 1s to 2s)
#
#    <VirtualHost *:80>
#
#        ServerName www.site2.com
#        ServerAlias site2.com
#        DocumentRoot /var/www/html/site2/
#        ErrorLog /var/www/html/site2/error.log
#        CustomLog /var/www/html/site2/requests.log combined
#    </VirtualHost>
#
# Create symbolic links from sites-available into sites-enabled
#
#    sudo ln -s /etc/httpd/sites-available/site1.com.conf /etc/httpd/sites-enabled/site1.com.conf
#    sudo ln -s /etc/httpd/sites-available/site2.com.conf /etc/httpd/sites-enabled/site2.com.conf
#
# Restart Apache
#    sudo service httpd restart
#    sudo setenforce 0 
#
# Method 2 ---------------------------------------------------------------
#    mkdir --parents /var/www/test.tutorialinux.com/public_html
#    Add /var/www/test.tutorialinux.com/public_html/index.html 
#
#    vi /etc/httpd/conf/httpd.conf (At very end of file, after IncludeOptional)
#
#    #Custom VirtualHosts
#    <VirtualHost *:80>
#        ServerAdmin webmaster@tutorialinux.com
#        DocumentRoot /var/www/test.tutorialinux.com/public_html
#        ServerName test.tutorialinux.com
#        ServerAlias tutorialinux.com
#        ErrorLog /var/www/test.tutorialinux.com/error.log
#    </VirtualHost>
#

# My config (currently broken, Unable to connect ...)
# Custom VirtualHost Definitions
#
#    <VirtualHost *:80>
#        ServerAdmin steve_gomez@usa.net
#        DocumentRoot /var/www/steven-gomez.com/public_html
#        ServerName steven-gomez.com
#        ServerAlias steven-gomez.com
#        ErrorLog /var/www/steven-gomez.com/error.log
#    </VirtualHost>
#    apachectl graceful
#
# Show DNS using /etc/hosts
#
# Add:
#    162.243.199.43 test.tutorialinux.com
#
# Method 2 ---------------------------------------------------------------
#
# From: https://docs.rockylinux.org/guides/web/apache-sites-enabled/
#
#    sudo mkdir --parents /etc/httpd/sites-available /etc/httpd/sites-enabled
#    sudo mkdir --parents /var/www/sub-domains 
#
#    sudo vi /etc/httpd/conf/httpd.conf (add at very end of file:)
#    Include /etc/httpd/sites-enabled
#
#    Our actual configuration files will be in /etc/httpd/sites-available and 
#    you will symlink to them in /etc/httpd/sites-enabled.
#
#    This method prevents changes to a single site's configuration from 
#    crashing ALL Apache configurations during a config reload.
#
#    This also allows fully specifying everything outside the default httpd.conf,
#    and makes troubleshooting a broken site's configuration less complex.
#
#
#    sudo vi /etc/httpd/sites-available/steven-gomez.com
#
#    <VirtualHost *:80>
#            ServerName steven-gomez.com
#            ServerAdmin username@rockylinux.org
#            DocumentRoot /var/www/sub-domains/steven-gomez.com/html
#            DirectoryIndex index.php index.htm index.html
#            Alias /icons/ /var/www/icons/
#            # ScriptAlias /cgi-bin/ /var/www/sub-domains/steven-gomez.com/cgi-bin/
#    
#        CustomLog "/var/log/httpd/steven-gomez.com-access_log" combined
#        ErrorLog  "/var/log/httpd/steven-gomez.com-error_log"
#    
#            <Directory /var/www/sub-domains/steven-gomez.com/html>
#                    Options -ExecCGI -Indexes
#                    AllowOverride None
#    
#                    Order deny,allow
#                    Deny from all
#                    Allow from all
#    
#                    Satisfy all
#            </Directory>
#    </VirtualHost>
#
#    OR - better yet, include the HTTPS directives needed to support let's encrypt keys.
#
#    <VirtualHost *:80>
#            ServerName steven-gomez.com
#            ServerAdmin steve_gomez@usa.net
#            Redirect / https://steven-gomez.com/
#    </VirtualHost>
#    <Virtual Host *:443>
#            ServerName steven-gomez.com
#            ServerAdmin steve_gomez@usa.net
#            DocumentRoot /var/www/sub-domains/steven-gomez.com/html
#            DirectoryIndex index.php index.htm index.html
#            # Alias /icons/ /var/www/icons/
#            # ScriptAlias /cgi-bin/ /var/www/sub-domains/steven-gomez.com/cgi-bin/
#    
#        CustomLog "/var/log/`http`d/steven-gomez.com-access_log" combined
#        ErrorLog  "/var/log/`http`d/steven-gomez.com-error_log"
#    
#            SSLEngine on
#            SSLProtocol all -SSLv2 -SSLv3 -TLSv1
#            SSLHonorCipherOrder on
#            SSLCipherSuite EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384
#    :EECDH+aRSA+SHA256:EECDH+aRSA+RC4:EECDH:EDH+aRSA:RC4:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS
#    
#            SSLCertificateFile /var/www/sub-domains/steven-gomez.com/ssl/ssl.crt/com.wiki.www.crt
#            SSLCertificateKeyFile /var/www/sub-domains/steven-gomez.com/ssl/ssl.key/com.wiki.www.key
#            SSLCertificateChainFile /var/www/sub-domains/steven-gomez.com/ssl/ssl.crt/your_providers_intermediate_certificate.crt
#    
#            <Directory /var/www/sub-domains/steven-gomez.com/html>
#                    Options -ExecCGI -Indexes
#                    AllowOverride None
#    
#                    Order deny,allow
#                    Deny from all
#                    Allow from all
#    
#                    Satisfy all
#            </Directory>
#    </VirtualHost>
#    
#
#
#
#    sudo mkdir --parents /var/www/sub-domains/steven-gomez.com/html
#    Then create the HTML in the directory created above.
#
#
#
#



##########################################################################
##########################################################################
##########################################################################
#
# URL & Application definitions

# Download (wget) the latest version directly from the wordpress.org
WORDPRESS_PKG=latest.tar.gz
WORDPRESS_URL=https://wordpress.org/${WORDPRESS_PKG}

PHP_MYADMIN_VER=5.2.2
PHP_MYADMIN_URL=https://files.phpmyadmin.net/phpMyAdmin/${PHP_MYADMIN_VER}/phpMyAdmin-${PHP_MYADMIN_VER}-english.tar.gz

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

    dnf install -y git wget unzip curl

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

    dnf install -y mariadb-server mariadb

    # The following displays version information for MariaDB
    rpm -qi mariadb-server

    systemctl enable --now mariadb

    echo "Function: InstallDataBase complete"
}
# ------------------------------------------------------------------------

##########################################################################
# Install PHP
# From: https://linuxcapable.com/how-to-install-php-on-rocky-linux/
#
function InstallPhp
{
    echo "Function: InstallPhp starting"

    # Enable CRB to provide access to more development tools
    sudo dnf config-manager --set-enabled crb

    # Install EPEL repositories
    sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
        https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm

    sudo dnf install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm
    sudo dnf module enable php:remi-8.4 -y

    # Apache (httpd) PHP Installation, and extra packages
    sudo dnf install -y php 
    sudo dnf install -y php-cli php-fpm php-curl php-mysqlnd php-gd php-opcache php-zip \
        php-common php-bcmath php-imagick php-xmlrpc php-json php-readline \
        php-memcached php-redis php-mbstring php-apcu php-xml php-dom php-redis \
        php-memcached php-memcache php-pear

    sudo dnf -y install php php-{cgi,gettext,imap,pdo,mysqli,odbc}

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
    dnf install -y policycoreutils-python-utils

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
function InstallApacheCertificates
{
    echo "Function: InstallApacheCertificates starting"

    # From: https://docs.rockylinux.org/guides/security/generating_ssl_keys_lets_encrypt/

    dnf -y install epel-release
    dnf -y install certbot python3-certbot-apache

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

    InstallWordPress
fi

#  Install the certificates
if [ $ACTION_TYPE = "ADD_CERTS" ]
then
    echo "========================================================================================="
    echo "=================== Setting up Certificates ============================================="
    echo "========================================================================================="

    InstallApacheCertificates

fi

