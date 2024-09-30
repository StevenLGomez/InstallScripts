
## Installation notes for Rocky Linux

### VirtualBox Installation

* Installing VirtualBox Guest Additions*

After completing minimal install, run the following as root:
Guest additions failed with minimal install, retrying with Minimal Server Install.
```
dnf -y update
dnf -y install epel-release
dnf -y install gcc make perl kernel-devel kernel-headers bzip2 dkms
dnf -y update kernel-*

reboot  # after reboot is finished, log back in as root.

# Use the VirtualBox menus to run Devices -> Insert Guest Additions CD Image

Used the run button, which gave an error message, but could still extend the GUI, so moving on...
```

* Steps for installing Podman*   

```
# VM settings (generic guidelines)
CPUs        4
Memory      8GB
HD          300 GB (thin)
Net Adapter E1000E

VM Name     podman-XXXX
OS          Rocky 9.3 (vCenter select RHEL 8 64-bit)
ISO         Rocky-9.3-x86_64-dvd.iso

IP          TBD

Users       root, developer
Install     minimal

If NTP is broken: set time/date using date -s 'YYYY-MM-DD hh:mm:ss'

visudo, then the commands below can be run as standard account using sudo
```

```
dnf -y udpate
dnf -y install git wget curl zip unzip container-* buildah podman skopeo slirp4netns
# Not needed, already installed: dnf -y install fuse-overlayfs iptables

# Enable user namespaces (already enabled ??)
echo "user.max_user_namespaces=28644" > /etc/sysctl.d/userns.conf
sysctl -p /etc/sysctl.d/userns.conf

# Configure to allow containers to run after initiating user has logged out
loginctl enable-linger
loginctl user-status | grep Linger  # << Should reply with Linger: yes

```

```
# Podman desktop setup

# Search for logo icon & download to ~/Desktop
# Download .tar.gz from [podman-desktop.io](https://podman-desktop.io/downloads)

# Create ~/bin directory
# unzip file downloaded above into ~/bin directory.

# Create file .local/share/applications/PodmanDesktop.desktop with contents:
#           NOTE - Path changes with version installed.

[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Podman Desktop
Comment=Container workflow automation
Icon=/home/developer/Desktop/podman-logo.png
Exec=/home/developer/bin/podman-desktop-1.6.3/podman-desktop
Terminal=false
Categories=Applications:Development

```

## TeamCity Installation Notes for RHEL/Rocky 9 ##

**Disk Configuration**

Drive | Size (MB)      | Provisioning | Format | Mount Point
----- | -------------- | ------------ | ------ | -----------
sda   | 35             | Thin         | ext4   | NA
sdb   | 50             | Thick, Eager | ext4   | /var/lib/mysql
sdc   | 50             | Thin         | ext4   | /opt/TcData

**Actions required before running the TeamCity.sh script**

- Perform minimal install using only /dev/sda.
- When base installation has finished, log in as root.

**Prepare external drives**  
Create partition on /dev/sdb & /dev/sdc using the following commands

`fdisk /dev/sdb `  
`n (to create a new partition)`  
`p (to make primary partition)`  
`1 (select partition 1)`  
`Enter 1 to start format at cylinder 1, or enter first cylinder available`  
`Enter (default to last cylinder to use all space)`  
`w (write partition table & exit)`  

**Format the drive partition created above**  
`mkfs -t ext4 /dev/sdb1`

### Repeat the steps above substituting /dev/sdc to format the third drive ###

**Create the mount points in the file system**  
`mkdir /var/lib/mysql`  
`mkdir /opt/TcData`

**Edit /etc/fstab, adding the following two lines:**  
`/dev/sdb1 /var/lib/mysql ext4  defaults  1 1`  
`/dev/sdc1 /opt/TcData ext4  defaults  1 1`
 
**Reboot the system; log in as root.  Check for presence of all three drives using:**  
`df -h`

**After confirming that the external drives connected properly, install git:**  
`dnf -y install git`

**A VM snapshot may be desired at this point.  To run the TeamCity installation script:**  
`mkdir repositories`  
`cd repositories`  
`git clone http://usstlgit03:7990/TBD/InstallScripts.git`  
`cd InstallScripts`  
`chmod +x TeamCity.sh`  
`./TeamCity.sh`

------------

**After the script has run to completion, configure the database:**  
`mariadb_secure_installation   <-- Assign root password \(**and remember it**\), then answer Y to all questions  

`mysql -u root -p       <-- Create database & access account for TeamCity`  
`create database cidb character set UTF8 collate utf8_bin;`  
`create user admin identified by 'firmware';`  
`grant all privileges on cidb.* to admin;`  
`grant process on *.* to admin;`  
`quit;`  

**After running script and entering all DB configurations as above, log in as admin
and start TeamCity service using:**  
`/opt/TeamCity/bin/teamcity-server.sh start`

**Open a web browser, and point to:  http://<URL>:8111**  
`Follow the directions in the browser.`

------------

