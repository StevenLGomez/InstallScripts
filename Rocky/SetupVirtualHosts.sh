
# https://www.devtutorial.io/how-to-set-up-apache-virtual-host-on-rocky-linux-9-p3346.html
# https://httpd.apache.org/docs/2.4/ssl/ssl_howto.html

sudo dnf update # May need to add --allowerasing if version collision is encountered
sudo mkdir /var/www/html/example

# Create sample page
sudo vi /var/www/html/example/index.html

<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Example.com</title>
</head>
<body>
    <h1>Success! Your Virtual Host is working!</h1>
</body>
</html>

sudo chown -R apache:apache /var/www/html/example
sudo chmod -R 755 /var/www/html/example

# Create a configuration file for your virtual host
sudo nano /etc/httpd/conf.d/example.conf

# Add the following configuration.  Replace "example.com" with your
# desired comain or subdomain.

# *******************************************************************
# *******************************************************************
# For steven-gomez.com /etc/httpd/conf.d/steven-gomez.conf
# WITHOUT SSL *******************************************************

<VirtualHost *:80>
    ServerAdmin webmaster@steven-gomez.com
    ServerName steven-gomez.com
    DocumentRoot /var/www/html/steven-gomez

    ErrorLog /var/log/httpd/steven-gomez_error.log
    CustomLog /var/log/httpd/steven-gomez_access.log combined

    <Directory /var/www/html/steven-gomez>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

# WITH SSL **********************************************************

<VirtualHost *:80>
        ServerName steven-gomez.com
        ServerAdmin steve.gomez.sg79@gmail.com
        #Redirect / https://steven-gomez.com/
</VirtualHost>
<Virtual Host *:443>
        ServerName steven-gomez.com
        ServerAdmin steve.gomez.sg79@gmail.com
        DocumentRoot /var/www/html/steven-gomez
        DirectoryIndex index.php index.htm index.html
        Alias /icons/ /var/www/icons/
        # ScriptAlias /cgi-bin/ /var/www/sub-domains/com.yourdomain.www/cgi-bin/

        CustomLog "/var/log/httpd/com.steven-gomez.www-access_log" combined
        ErrorLog  "/var/log/httpd/com.steven-gomez.www-error_log"

        SSLEngine on
        SSLProtocol all -SSLv2 -SSLv3 -TLSv1
        SSLHonorCipherOrder on
#        SSLCipherSuite EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384
#:EECDH+aRSA+SHA256:EECDH+aRSA+RC4:EECDH:EDH+aRSA:RC4:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS

        #SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4

        #SSLCipherSuite RC4-SHA:AES128-SHA:HIGH:!aNULL:!MD5

        SSLCertificateFile /etc/letsencrypt/live/gomez.engineering/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/gomez.engineering/privkey.pem

        <Directory /var/www/html/steven-gomez>
                Options -ExecCGI -Indexes
                AllowOverride None

                Order deny,allow
                Deny from all
                Allow from all

                Satisfy all
        </Directory>
</VirtualHost>

# *******************************************************************
# *******************************************************************
# For gomez.engineering /etc/httpd/conf.d/gomez-engineering.conf
# WITHOUT SSL *******************************************************

<VirtualHost *:80>
    ServerAdmin steve.gomez.sg79@gmail.com
    ServerName gomez.engineering
    DocumentRoot /var/www/html/gomez-engineering

    ErrorLog /var/log/httpd/gomez-engineering_error.log
    CustomLog /var/log/httpd/gomez-engineering_access.log combined

    <Directory /var/www/html/gomez-engineering>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

# WITH SSL **********************************************************

<VirtualHost *:80>
        ServerName gomez.engineering
        ServerAdmin steve.gomez.sg79@gmail.com
        #Redirect / https://gomez.engineering/
</VirtualHost>
<VirtualHost *:443>
        ServerName gomez.engineering
        ServerAdmin steve.gomez.sg79@gmail.com
        DocumentRoot /var/www/html/gomez-engineering
        DirectoryIndex index.php index.htm index.html
        Alias /icons/ /var/www/icons/
        # ScriptAlias /cgi-bin/ /var/www/sub-domains/com.yourdomain.www/cgi-bin/

        CustomLog "/var/log/httpd/com.gomez-engineering.www-access_log" combined
        ErrorLog  "/var/log/httpd/com.gomez-engineering.www-error_log"

        SSLEngine on
        SSLProtocol all -SSLv2 -SSLv3 -TLSv1
        SSLHonorCipherOrder on
#        SSLCipherSuite EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384
#:EECDH+aRSA+SHA256:EECDH+aRSA+RC4:EECDH:EDH+aRSA:RC4:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS
        
        # SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4

        #SSLCipherSuite RC4-SHA:AES128-SHA:HIGH:!aNULL:!MD5

        SSLCertificateFile /etc/letsencrypt/live/gomez.engineering/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/gomez.engineering/privkey.pem

        <Directory /var/www/html/gomez-engineering>
                Options -ExecCGI -Indexes
                AllowOverride None

                Order deny,allow
                Deny from all
                Allow from all

                Satisfy all
        </Directory>
</VirtualHost>

# Check the Apache configuration for syntax errors
sudo apachectl configtest  # Showed warning about FQDN: Set the 'ServerName' directive globally to suppress this message

# if warnings are received concerning lack of ServerName definition, edit /etc/httpd/conf/httpd.conf to set the 
# ServerName directive to 127.0.0.1

# Restart apache if no errors
sudo systemctl restart httpd


######################################################
# Below was removed & copied from Lamp.sh
######################################################


##########################################################################
# From: https://docs.rockylinux.org/guides/web/apache-sites-enabled/
# NOTE  Apache uses the first virtual host found in the configuration also for
#       requests that do not match any domain set in the ServerName and
#       ServerAlias parameters. This also includes requests sent to the IP
#       address of the server.
#
function ConfigureMultiSiteDirectories
{
    echo "Function: ConfigureMultiSiteDirectories starting"

    # Update Apache configuration, Include the sites-enabled path
    sudo echo '' >> /etc/httpd/conf/httpd.conf
    sudo echo 'Include /etc/httpd/sites-enabled' >> /etc/httpd/conf/httpd.conf
    sudo echo '' >> /etc/httpd/conf/httpd.conf
    sudo echo 'ServerName steven-gomez.com:80' >> /etc/httpd/conf/httpd.conf
    sudo echo 'ServerName gomez.engineering:80' >> /etc/httpd/conf/httpd.conf
    sudo echo '' >> /etc/httpd/conf/httpd.conf


    # NOTE NOTE - could not sudo add the following 
    # NOTE: also manually added (to /etc/httpd/conf/httpd.conf), but NOT commented.
    # ServerName steven-gomez.com:80
    # ServerName gomez.engineering:80

    echo "Function: ConfigureMultiSiteDirectories complete"
}
# ------------------------------------------------------------------------


##########################################################################
function ConfigureSiteA
{
    # Add the subdirectories needed for your supported site and its associated keys
    sudo mkdir --parents /var/www/sub-domains/steven-gomez.com/html
    sudo mkdir --parents /var/www/sub-domains/steven-gomez.com/ssl/{ssl.key,ssl.crt,ssl.csr}
    # sudo chown -R apache:apache /var/www/sub-domains

    # Create the multi site configuration file, modify and add <VirtualHost>s as needed:
cat << EOF > /etc/httpd/sites-available/steven-gomez.com
<VirtualHost *:80>
        ServerName steven-gomez.com
        ServerAdmin steve.gomez.sg79@gmail.com
        DocumentRoot /var/www/sub-domains/steven-gomez.com/html/
        CustomLog "/var/log/httpd/steven-gomez.com-access_log" combined
        ErrorLog  "/var/log/httpd/steven-gomez.com-error_log"
#        Redirect / https://steven-gomez.com/
</VirtualHost>
#<VirtualHost *:443>
#        ServerName steven-gomez.com
#        ServerAdmin steve.gomez.sg79@gmail.com
#        DocumentRoot /var/www/sub-domains/steven-gomez.com/html/
#        DirectoryIndex index.php index.htm index.html
#        Alias /icons/ /var/www/icons/
#        # ScriptAlias /cgi-bin/ /var/www/sub-domains/steven-gomez.com/cgi-bin/
#
#        CustomLog /var/log/httpd/steven-gomez.com-access_log combined
#        ErrorLog  /var/log/httpd/steven-gomez.com-error_log
#
#        SSLEngine on
#        SSLProtocol all -SSLv2 -SSLv3 -TLSv1
#        SSLHonorCipherOrder on
#
#        SSLCertificateFile /etc/letsencrypt/live/steven-gomez.com/fullchain1.pem
#        SSLCertificateKeyFile /etc/letsencrypt/live/steven-gomez.com/privkey1.pem
#        SSLCertificateChainFile /etc/letsencrypt/live/steven-gomez.com/fullchain.pem:w
#
#        <Directory /var/www/sub-domains/steven-gomez.com/html>
#                Options -ExecCGI -Indexes
#                AllowOverride None
#
#                Order deny,allow
#                Deny from all
#                Allow from all
#
#                Satisfy all
#        </Directory>
#</VirtualHost>
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
        <hr />
        <?php phpinfo(); ?> 
  </body>

</html>
EOF
    # Change ownership of the file just created
    # chown apache:apache /var/www/sub-domains/steven-gomez.com/html/index.html

    # Create dummy php test page in this sub-domain
    # echo "<?php phpinfo(); ?>" > /var/www/sub-domains/steven-gomez.com/html/info.php
    # chown apache:apache /var/www/sub-domains/steven-gomez.com/html/info.php

    # This line makes this site live by making it visible in sites-enabled
    ln -s /etc/httpd/sites-available/steven-gomez.com /etc/httpd/sites-enabled/

}
# ------------------------------------------------------------------------

##########################################################################
function ConfigureSiteB  
{
    # Add the subdirectories needed for your supported site and its associated keys
    sudo mkdir --parents /var/www/sub-domains/gomez.engineering/html
    sudo mkdir --parents /var/www/sub-domains/gomez.engineering/ssl/{ssl.key,ssl.crt,ssl.csr}
    # sudo chown -R apache:apache /var/www/sub-domains

    # Create the multi site configuration file, modify and add <VirtualHost>s as needed:
cat << EOF > /etc/httpd/sites-available/gomez.engineering
<VirtualHost *:80>
        ServerName gomez.engineering
        ServerAdmin steve.gomez.sg79@gmail.com
        DocumentRoot /var/www/sub-domains/gomez.engineering/html/
        CustomLog "/var/log/httpd/gomez.engineering-access_log" combined
        ErrorLog  "/var/log/httpd/gomez.engineering-error_log"
#        Redirect / https://gomez.engineering/
</VirtualHost>
#<VirtualHost *:443>
#        ServerName gomez.engineering
#        ServerAdmin steve.gomez.sg79@gmail.com
#        DocumentRoot /var/www/sub-domains/gomez.engineering/html/
#        DirectoryIndex index.php index.htm index.html
#        Alias /icons/ /var/www/icons/
#        # ScriptAlias /cgi-bin/ /var/www/sub-domains/gomez.engineering/cgi-bin/
#
#        CustomLog /var/log/httpd/gomez.engineering-access_log combined
#        ErrorLog  /var/log/httpd/gomez.engineering-error_log
#
#        SSLEngine on
#        SSLProtocol all -SSLv2 -SSLv3 -TLSv1
#        SSLHonorCipherOrder on
#
#        #sudo cp /etc/letsencrypt/archive/gomez.engineering/privkey1.pem ssl.key/
#        #sudo cp /etc/letsencrypt/archive/gomez.engineering/fullchain1.pem ssl.crt/ 
#
#        #SSLCertificateKeyFile /etc/letsencrypt/live/gomez.engineering/privkey1.pem
#        #SSLCertificateFile /etc/letsencrypt/live/gomez.engineering/fullchain1.pem
#
#        SSLCertificateKeyFile /var/www/sub-domains/gomez.engineering/ssl/ssl.key/privkey1.pem
#        SSLCertificateFile /var/www/sub-domains/gomez.engineering/ssl/ssl.crt/fullchain1.pem
#
#        <Directory /var/www/sub-domains/gomez.engineering/html>
#                Options -ExecCGI -Indexes
#                AllowOverride None
#
#                Order deny,allow
#                Deny from all
#                Allow from all
#
#                Satisfy all
#        </Directory>
#</VirtualHost>
EOF

    # Make a test landing page
cat << EOF > /var/www/sub-domains/gomez.engineering/html/index.html
<html>
  <head>
    <title>Apache Server Test Page</title>
  </head>

  <body>
    <h1>Web site on Rocky Linux 9</h1>
	gomez.engineering
        <hr />
        <?php phpinfo(); ?> 
  </body>

</html>
EOF
    # Change ownership of the file just created
    # chown apache:apache /var/www/sub-domains/gomez.engineering/html/index.html

    # Create dummy php test page in this sub-domain
    # echo "<?php phpinfo(); ?>" > /var/www/sub-domains/gomez.engineering/html/info.php
    # chown apache:apache /var/www/sub-domains/gomez.engineering/html/info.php

    # This line makes this site live by making it visible in sites-enabled
    ln -s /etc/httpd/sites-available/gomez.engineering /etc/httpd/sites-enabled/
}
# ------------------------------------------------------------------------








