# Installation steps borrowed from NPSV Documentation

# 20201003 - Modified for CentOS 8 to reinstall on esximgmt
#
# Created base VM using:
# 4 CPUs
# 8 GB Ram
# 25 GB hard drive - thin provisioned
#
# After installation, shutdown and added secondary HD
# 70 GB - Thick provisioned
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

# Create mount point directory for MariaDB
# mkdir /var/lib/mysql

# Edit /etc/fstab & add:
# /dev/sdb1 /var/lib/mysql ext4  defaults  1 1
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





yum -y update
yum -y install open-vm-tools
yum -y install wget unzip rsync java-1.8.0-openjdk-headless
shutdown -h now

# Add secondary drive for data (in ESXi)
# Used 70 GB for drive size, THICK Provision for database
# Reboot & log in as root

fdisk /dev/sdb
n (to create a new partition)
p (to make this the primary partition)
1 (select partition 1)
Enter 1 to start format at cylinder 1, or enter first cylinder available
Enter (default to last cylinder to use all space)
w (write partition table & exit)

# Format the drive partition created above
mkfs -t ext4 /dev/sdb1
mkdir /external

# Edit /etc/fstab & add:
/dev/sdb1 /external ext4  defaults  1 1

# Edit /home/admin/.bashrc & add the following to the end of the file:
export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk

# Reboot, after rebooting, log in as root and confirm secondary drive is present:
df -h


# 
# Open the necessary ports for web services
firewall-cmd --zone=public --permanent --add-port=8111/tcp
firewall-cmd --reload

# Install MariaDB
dnf -y install mariadb-server
systemctl start mariadb
systemctl status mariadb <<== Should show "active (running)"

systemctl enable mariadb

# Securing DB
mysql_secure_installation

mysqladmin -u root -p version
# Set root password = Cs..44, yes to all others

mysqladmin -u root -p version




