### A collection of notes for using Debian VMs ###

### Installing on Windoze host with Virtual Box Version 6.1.18 r142142 (Qt5.6.2) ###

Install OS using packages needed for whatever purpose you need.  AFter the initial  
it will be necessary to install the Guest Additions to be able to make the screen  
size usable.  
To install the GAs, I used these steps (borrowed from various places on the web).  

- Log in as root using `su -` and enter the root password assigned during install.  
- `apt install -y build-essential module-assistant`  
- `m-a prepare`
- `apt install -y linux-headers-$(uname -r)`
- Reboot
- Log in as root again  
- Using VBox menus: Devices -> Insert Guest Additions CD Image.  A Run dialog will open; ignore it.  
- Open File Browser.
- Copy all contents of the GA image to ~/Documents/vbox
- In the shell, navigate to the vbox directory just created.
- `chmod +x VBoxLinuxAdditions.run`  
- `sh ./VBoxLinuxAdditions.run`
- If all goes well, close the GA dialog, and unmount it using Devices -> Optical Drives -> Remove disc from virtual drive  
- Reboot
- You should now be able to drag the screen to full size.

## Installing Podman
- As root...
- `apt -y update && apt -y upgrade`  
- `apt -y install gcc make cmake git btrfs-progs golang-go go-md2man iptables`  
- `apt -y install libassuan-dev libc6-dev libdevmapper-dev libglib2.0-dev libgpgme-dev`  
- `apt -y install libgpg-error-dev libostree-dev libprotobuf-dev libprotobuf-c-dev`  
- `apt -y install libseccomp-dev libselinux1-dev libsystemd-dev pkg-config runc uidmap libapparmor-dev`  
- As standard user...
- `git clone https://github.com/containers/conmon`  
- `cd conmon`  
- `make`  
- As root...
- `make podman`  
- `cp /usr/local/libexec/podman/conmon  /usr/local/bin/`  
- Install CNI plugins
- `git clone https://github.com/containernetworking/plugins.git $GOPATH/src/github.com/containernetworking/plugins`  
- `cd $GOPATH/src/github.com/containernetworking/plugins`  
- `./build_linux.sh`  
- `sudo mkdir -p /usr/libexec/cni`  
- `sudo cp bin/* /usr/libexec/cni`  
- ... Podman installation went south from here.  Abandoned, returning to C8


