# Linux Mint 19.1 (xfce) Installation Notes

## Update issues (after fresh install)
When installing with the associated script (fresh install from Linux Mint 19.1 xfce)
would encounter failures during update/upgrade

Workaround has obtained from:
https://forums.linuxmint.com/viewtopic.php?f=47&t=295975

Specfic steps I used to get successful base install to run my install script against:
Perform fresh install (selected "Install multimedia, MP3, etc option"), then on first boot, open Terminal and run:

* sudo apt-get -y update
* sudo apt-get -y upgrade # <= Allow it to run, but will fail
* sudo dpkg --configure -a
* sudo apt install -f
* sudo apt-get -y upgrade # <= Will succeed this time
* --REBOOT--

After the reboot, prepare for and run the script using:

* sudo apt install git
* git clone <InstallScripts.git>
* cd InstallScripts/LinuxMint
* chmod +x LM19_WorkstationInstall.sh
* Answer yes to jackctl question
* sudo ./LM19_workstationInstall.sh
* --REBOOT--

## VMware Installation

Initial attemps of installing VMRC and Player during script execution were unsuccessful.  When attempting install of either application, would encounter the message:

```An up to date libaio or libaio1 package from your system is preferred```

Tried to see which one would install:

* sudo apt install libaio  # <= This failed
* sudo apt install libaio1 # <= This was successful

So the install script was modified to install libaio1 with the development packages.

* sudo ./VMware-Player-15.1.0-13591040.x86_64.bundle # <= /usr/bin/vmplayer installed OK and runs (on VM)
* --REBOOT--
* sudo ./VMware-Remote-Console-10.0.4-11818843.x86_64.bundle # <= Extracting VMware Installer...done, but does NOT run :(
* sudo sh ./VMware-Remote-Console-10.0.4-11818843.x86_64.bundle # <= Fails the same :(  :(

## Post Installation Saga

VMware Player would not install, gave message that CPU was too old.  Research showed that VMware has started obsoleting CPU families with version 14 of Workstation (which includes Player).  So I managed to find Player version 12 on myvmware.com.  I installed it, it shows up in the Mint menus, but appears to do nothing when attempting to start it.  From a shell, entering /usr/bin/vmplayer & doesn't start it either, but you see the message:

```/usr/lib/vmware/bin/vmware-modconfig: Relink `/lib/x86_64-linux-gnu/libbsd.so.0' with `/lib/x86_64-linux-gnu/librt.so.1' for IFUNC symbol `clock_gettime'```

Tried installation of VMRC, seemed to be OK, but the installer finished with the message "Installation unsuccessful".  When attempting to start it get the message (in a pop up dialog):

``` Failed to open URI "vmrc://clone:cst-52d797ca-bafd-1ea5-3721-af01cb7fb40e--tp-A8-B6-AD-50-4A-C9-A3-C7-5E-85-1C-70-98-1E-A3-B6-22-21-75@esximgmt/?moid=9" The specified location is not supported.```

Maybe its time for VirtualBox!!

Final attempt (hopefully), is to install VMRC (NOT Player), and install VirtualBox 6.0.  Taking a stab at it on the VM.

### Tux Guitar

Installation of Tux Guitar was included in the associated install script, along with support utilities for getting the sound to work.  However Mint installs version 1.2.23, but I had been making some exercise files using 1.5.2 on my CentOS laptop. 

* Found & downloaded tuxguitar-1.5.2-linux-x86_64.deb on SourceForge
* sudo dpkg -i ~/Downloads/tuxguitar*.deb; sudo apt-get -f install
It complained about various Java version concerns, but after it finished, Tux started right up and was able to open one my exercise files made previously on 1.5.2.  Hooray !!



