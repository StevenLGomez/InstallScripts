
##########################################################################
# https://certbot.eff.org/lets-encrypt/centosrhel7-apache
function InstallEncryptClient
{
    echo "Function: InstallEncryptClient starting"
    
    # Red Hat installations require these commands 
    # TODO - NOTE that REGION must be updated with the appropriate Amazon Elastic Compute Cloud (EC2) region
    # yum -y install yum-utils
    # yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional

    yum -y install certbot python2-certbot-apache mod_ssl

    # Stop the Apache server before getting the certificate
    systemctl stop httpd
    
    # TODO: Add code to get the certificate
    certbot --apache
    # certbot certonly --apache # <- Run this if manual Apache configuration is needed
    
    # TODO: Add code to restart apache
    systemctl start httpd
    
    # Set the default crontab to automatically renew the certificate
    echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew" | sudo tee -a /etc/crontab > /dev/null

    echo "Function: InstallEncryptClient complete"
}
# ------------------------------------------------------------------------
 
