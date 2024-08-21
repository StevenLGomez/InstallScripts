
# Script to install Visual Studio Code on RHEL/CentOS 
# 
# Based on instructions borrowed from:
# https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions
#
# Introductory videos are available:
# https://code.visualstudio.com/docs/getstarted/introvideos

# Set up the Microsoft Repositories 
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

# Install 
dnf check-update
dnf install code
