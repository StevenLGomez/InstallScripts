#!/bin/bash

# 20201003 - Modified for CentOS 8 to reinstall on esximgmt
#
# Created base VM using:
# 2 CPUs
# 2 MB Ram
# 30 GB hard drive - thin provisioned
#
# After installation, shutdown and added secondary HD
# 500 GB - thin provisioned
#
# Prepare secondary drive as followws:
# fdisk /dev/sdb
# n (to create a new partition)
# p (to make primary partition)
# 1 (select partition 1)
# Enter 1 to start format at cylinder 1, or enter first cylinder available
# Enter (default to last cylinder to use all space)
# w (write partition table & exit)

# Format the drive partition created above
# mkfs -t ext4 /dev/sdb1

# Edit /etc/fstab & add:
# /dev/sdb1 /media ext4  defaults  1 1
#
# Reboot and confirm secondary drive is present using
# df -h 
#
# Must also install wget to be able to get this script from internal web server
#

# Server log file is:  /var/log/squeezeboxserver/server.log 

# The following are from the slimdevices web site
# id squeezeboxserver
# ln -s -T /usr/lib/perl5/vendor_perl/Slim /usr/share/perl5/vendor_perl/Slim
# service logitechmediaserver start


# The Squeezebox Server is stored on internal server
# Define parameters that may change over time....
APPLICATION_SERVER_URL=http://10.1.1.26/Applications/Logitech/
MEDIASERVER_RPM=logitechmediaserver-7.9.3-1.noarch.rpm

SQUEEZEBOX=${APPLICATION_SERVER_URL}/${MEDIASERVER_RPM}

# Perform update and install the necessary support applications
# ====================================================================
yum -y update

# Perl tools
yum -y install perl
yum -y install perl-Time-HiRes 
yum -y install perl-CGI
yum -y install perl-Digest-MD5

# Miscellaneous tools
yum -y install rsync
yum -y install wget
yum -y install open-vm-tools

# Start the media server installation
# ====================================================================

# Download and install the media server
wget ${SQUEEZEBOX}
# rpm -ivh logitechmediaserver-7.7.6-1.noarch.rpm 
yum -y localinstall ./${MEDIASERVER_RPM}

# Fix some perl paths that apparently are specific to CentOS
ln -s /usr/lib/perl5/vendor_perl/Slim /usr/lib64/perl5/Slim

# Open up firewall ports
firewall-cmd --zone=public --add-port=9000/tcp --permanent
firewall-cmd --zone=public --add-port=3483/tcp --permanent
firewall-cmd --zone=public --add-port=3483/udp --permanent
firewall-cmd --reload

systemctl start squeezeboxserver
systemctl enable squeezeboxserver

# Add the admin user to the squeezeboxserver group
usermod -g squeezeboxserver admin

# Create Playlist directory, and update its permissions
mkdir /media/Playlists
chown -R admin:squeezeboxserver /media/Playlists

# Create MusicCollection directory, and update its permissions
mkdir /media/MusicCollection
chown -R admin:squeezeboxserver /media/MusicCollection

# Optional step: 
# If you want to enable the transcoding feature in LMS, you'll have to install the LAME MP3 encoder. 
# The LAME software is not available in the default EL7 repositories, so you'll have to add a 
# 3rd party repository to install it.
# cd /etc/yum.repos.d/
# wget http://negativo17.org/repos/epel-handbrake.repo
# yum -y install lame

# Make some updates to /etc/hosts for networking
echo '' >> /etc/hosts
echo '# Local IP addresses' >> /etc/hosts
echo '10.1.1.45    porker.gomezengineering.lan                porker          #NetGear ReadyNAS' >> /etc/hosts
echo '' >> /etc/hosts

