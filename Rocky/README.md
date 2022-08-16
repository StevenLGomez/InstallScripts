
## Installation notes for Rocky Linux

### VirtualBox Installation

* Installing VirtualBox Guest Additions

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

* Steps for installing Podman
```
dnf -y udpate
dnf -y module install container-tools
dnf -y install git podman-docker

dnf -y install slirp4netns podman
echo "user.max_user_namespaces=28644" > /etc/sysctl.d/userns.conf

sysctl -p /etc/sysctl.d/userns.conf

# Allow admin user to manipulate files in /opt directory
cd /opt
chown –R admin:admin ./

```




