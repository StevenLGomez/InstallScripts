

# Installs Laravel PHP Web Framework

# MUST FIRST install LAMP server using Lamp.sh and following post install steps
# ALSO, make sure Apache, PHP & PhpMyAdmin are all running 

# After installing Composer, needed to add the following to .bashrc 
# (right before export PATH).
# PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Then...
# The following line not tested (was problematic for initial install ??)
# May need to run as non-root
#    composer global require laravel/installer

# Then...
# From a working directory:
#    laravel new <project name> 
#        Options:
#        No Starter kit
#        PHPUnit 
#        No Git Repository (works best after the creation) 
#        MariaDB 
#        Initialize DB 
#        ALSO found that it was required to create a DB and update .env 
#           DB_DATABASE
#           DB_USERNAME
#           DB_PASSWORD

##########################################################################
#
function InstallLaravel
{
    echo "Function: InstallLaravel starting"

    # Download Composer, then move it into a global path
    curl -s https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer


    echo "Function: InstallLaravel complete"
}
# ------------------------------------------------------------------------

# ====================================================================================
# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================

InstallLaravel

