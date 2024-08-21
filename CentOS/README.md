
# Install Script Support Information #

## TeamCity Installation Notes for RHEL/CentOS 8 ##

**Disk Configuration**

Drive | Size (MB)      | Provisioning | Format | Mount Point
----- | -------------- | ------------ | ------ | -----------
sda   | 35             | Thin         | ext4   | NA
sdb   | 50             | Thick, Eager | ext4   | /var/lib/mysql
sdc   | 50             | Thin         | ext4   | /opt/TCData

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
`mkdir /opt/TCData`

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
`mysql_secure_installation   <-- Assign root password \(**and remember it**\), then answer Y to all questions  

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

## Containerization (Kubernetes/Docker - OpenShift/Podman) Server Installation Notes ##

**Basic Configuration**

CPUs  | Memory (GB) | Installation Type
----- | ----------- | -----------------
4     | 4           | Basic Workstation

**Disk Configuration**

Drive | Size (MB)      | Provisioning | Format | Mount Point
----- | -------------- | ------------ | ------ | -----------
sda   | 250            | Thin         | ext4   | NA

**Related installation script: Kubernetes.sh**
Has demonstrated to successfully install Podman, but needs a LOT of cleanup.  

Kubernetes/OpenShift steps are TBD.
