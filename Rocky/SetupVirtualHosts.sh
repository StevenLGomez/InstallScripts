
# https://www.devtutorial.io/how-to-set-up-apache-virtual-host-on-rocky-linux-9-p3346.html

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

# For steven-gomez.com /etc/httpd/conf.d/steven-gomez.conf

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

# For gomez.engineering /etc/httpd/conf.d/gomez-engineering.conf

<VirtualHost *:80>
    ServerAdmin webmaster@steven-gomez.com
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



# Check the Apache configuration for syntax errors
sudo apachectl configtest  # Showed warning about FQDN: Set the 'ServerName' directive globally to suppress this message

# Restart apache if no errors
sudo systemctl restart httpd


