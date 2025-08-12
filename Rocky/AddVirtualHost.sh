
# Environment Variables needed to support configuration of specific sites
# SERVER_NAME   maps to     ServerName
# SERVER_ADMIN  maps to     ServerAdmin

# Constants
SUBDOMAIN_PATH=/var/www/sub-domains
AVAILABLE_PATH=/etc/httpd/sites-available 
ENABLED_PATH=/etc/httpd/sites-enabled
LOG_PATH=/var/log/httpd

# TEST Constants
#SUBDOMAIN_PATH=~/tmp/vtest/sub-domains
#AVAILABLE_PATH=~/tmp/vtest/sites-available 
#ENABLED_PATH=~/tmp/vtest/sites-enabled
#LOG_PATH=~/tmp/vtest/log/httpd
# SERVER_NAME=steven-gomez.com
# SERVER_ADMIN=steve.gomez.sg79@gmail.com

##########################################################################
# Create directories needed for this VirtualHost
#
function CreateVirtualHostDirectories
{
    echo "Creating Virtual Host Directories"

    # Add the subdirectories needed for this site and its associated keys
    mkdir --parents ${SUBDOMAIN_PATH}/${SERVER_NAME}/html
    mkdir --parents ${SUBDOMAIN_PATH}/${SERVER_NAME}/ssl/{ssl.key,ssl.crt,ssl.csr}

    mkdir --parents ${AVAILABLE_PATH}
    mkdir --parents ${ENABLED_PATH}
}
# ------------------------------------------------------------------------

# ====================================================================================
# cat << EOF > /etc/httpd/sites-available/steven-gomez.com
#
function CreateVirtualHostConfiguration
{
    echo "Creating Virtual Host Configuration"

cat << EOF > ${AVAILABLE_PATH}/${SERVER_NAME}
<VirtualHost *:80>
        ServerName ${SERVER_NAME}
        ServerAdmin ${SERVER_ADMIN}
        DocumentRoot ${SUBDOMAIN_PATH}/${SERVER_NAME}/html/
        ErrorLog  "${LOG_PATH}/${SERVER_NAME}-error_log"
        CustomLog "${LOG_PATH}/${SERVER_NAME}-access_log" combined
#        Redirect / https://${SERVER_NAME}/
</VirtualHost>
#<VirtualHost *:443>
#        ServerName ${SERVER_NAME}
#        ServerAdmin ${SERVER_ADMIN}
#        DocumentRoot ${SUBDOMAIN_PATH}/${SERVER_NAME}/html/
#        DirectoryIndex index.php index.htm index.html
#        Alias /icons/ /var/www/icons/
#        # ScriptAlias /cgi-bin/ ${SUBDOMAIN_PATH}/${SERVER_NAME}/cgi-bin/
#
#        ErrorLog  "${LOG_PATH}/${SERVER_NAME}-error_log"
#        CustomLog "${LOG_PATH}/${SERVER_NAME}-access_log" combined
#
#        SSLEngine on
#        SSLProtocol all -SSLv2 -SSLv3 -TLSv1
#        SSLHonorCipherOrder on
#
#        SSLCertificateFile /etc/letsencrypt/live/${SERVER_NAME}/fullchain1.pem
#        SSLCertificateKeyFile /etc/letsencrypt/live/${SERVER_NAME}/privkey1.pem
#        SSLCertificateChainFile /etc/letsencrypt/live/${SERVER_NAME}/fullchain.pem
#
#        <Directory ${SUBDOMAIN_PATH}/${SERVER_NAME}/html>
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

}
# ------------------------------------------------------------------------


# ====================================================================================
# cat << EOF > /var/www/sub-domains/steven-gomez.com/html/index.html
#
function CreateLandingPage
{
    echo "Creating Landing Page"

cat << EOF > ${SUBDOMAIN_PATH}/${SERVER_NAME}/html/index.html
<html>
  <head>
    <title>Apache Server Test Page</title>
  </head>

  <body>
    <h1>Web site on Rocky Linux 9</h1>
        <hr />
        Landing page for ${SERVER_NAME}
        <hr />
  </body>

</html>
EOF

}
# ------------------------------------------------------------------------

# ====================================================================================
# Create a link to make this site visible in sites-enabled
#
function CreateEnableSiteLink
{
    echo "Creating Link To Enable Site"
    ln -s ${AVAILABLE_PATH}/${SERVER_NAME} ${ENABLED_PATH}
}
# ------------------------------------------------------------------------

# ====================================================================================
# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================
#

# Requires script name + two parameters
if [[ $# -ne 2 ]]
then
    echo "Usage: $0 <SERVER_NAME> <SERVER_ADMIN>"
    echo "Where SERVER_NAME is the site's name and SERVER_ADMIN is the Administrator's email"
    exit
fi

# Echo the valid command line entry
echo Running: $0 SERVER_NAME $1 SERVER_ADMIN $2 

# Assign the command line parameters to the internal variables
SERVER_NAME=$1
SERVER_ADMIN=$2

CreateVirtualHostDirectories
CreateVirtualHostConfiguration
CreateLandingPage
CreateEnableSiteLink

