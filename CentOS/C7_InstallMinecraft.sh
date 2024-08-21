#!/bin/sh

# Stop & remove NetworkManager
#systemctl stop NetworkManager.service
#yum remove -y NetworkManager

# Enable network
#systemctl enable network.service
#systemctl start network.service

# in /etc/sysconfig/network-scripts/ifcfg<ifname>
# make sure ONBOOT = yes
#           BOOTPROTO = static or dhcp as desired

yum -y install java-1.8.0-openjdk-headless
echo "export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk" >> /home/admin/.bashrc




