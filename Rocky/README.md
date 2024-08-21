
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



