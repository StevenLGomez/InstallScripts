#!/bin/bash

#####################################################################
#####################################################################
#
# Linux Mint Workstation Application Installation Script
#
# Provides functions to install various groups of applications
# Functions may be disabled by commenting their call point at 
# the bottom of the script
#
# Comments in the individual functions describe their intent
#
#
#####################################################################
#####################################################################

# APPLICATION_SERVER_URL=http://10.17.20.62/Applications
APPLICATION_SERVER_URL=http://10.1.1.26/Applications

# List of things that are downloaded from internal server
# PY34_SOURCE=${APPLICATION_SERVER_URL}/Python/3.4.4/Python-3.4.4.tgz

# SlickEdit definitions
SE_VERSION=25000100
SE_TAR=se_${SE_VERSION}_linux64.tar.gz
SE_KEY=SE_VLX818071_2300_Gomez.lic
SLICKEDIT_INSTALLER=${APPLICATION_SERVER_URL}/SlickEdit/${SE_TAR}
SLICKEDIT_KEY=${APPLICATION_SERVER_URL}/SlickEdit/${SE_KEY}

# VMware definitions
# Install VMRC using sudo sh VMware-Remote-Console-10.0.4-11818843.x86_64.bundle
VMRC=VMware-Remote-Console-10.0.4-11818843.x86_64.bundle
VMRC_INSTALLER=${APPLICATION_SERVER_URL}/Packages/${VMRC}

# Install VMRC using sudo sh VMware-Player-15.1.0-13591040.x86_64.bundle
VMPLAYER=VMware-Player-12.5.9-7535481.x86_64.bundle
# LICENSE=open_source_license_VMware_Workstation_15.1.0_Pro_and_Player_GA.txt
VMPLAYER_INSTALLER=${APPLICATION_SERVER_URL}/Packages/${VMPLAYER}
# VMPLAYER_LICENSE=${APPLICATION_SERVER_URL}/Packages/${LICENSE}

# Virtual Box Definitions
VIRTUAL_BOX=virtualbox-6.0_6.0.8-130520_Ubuntu_bionic_amd64.deb
VBOX_INSTALLER=${APPLICATION_SERVER_URL}/Packages/${VIRTUAL_BOX}

# Google Chrome definitions
CHROME=google-chrome-stable_current_amd64.deb
CHROME_PACKAGE=${APPLICATION_SERVER_URL}/Packages/${CHROME}

TUX_GUITAR=tuxguitar-1.5.2-linux-x86_64.deb
TUX_GUITAR_INSTALLER=${APPLICATION_SERVER_URL}/Packages/${TUX_GUITAR}


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
function PerformUpdate
{
echo "Function: PerformUpdate"

sudo apt-get -y update

# After the update command completes, per Linux Mint forums, the
# following commands are required because the package manager
# is not configured correctly after a fresh install.
sudo dpkg --configure -a
sudo apt-get install -f

echo "Function: PerformUpdate completed"
}
# -------------------------------------------------------------------

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
function PerformUpgrade
{
echo "Function: PerformUpgrade"

sudo apt-get -y upgrade
# sudo apt-get -y dist-upgrade

echo "Function: PerformUpgrade completed"
}
# -------------------------------------------------------------------

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
function InstallDevelopmentTools
{
echo "Function: InstallDevelopmentTools"

sudo apt install -y gcc build-essential
sudo apt install -y git subversion
sudo apt install -y gitk
sudo apt install -y git-gui
sudo apt install -y htop
sudo apt install -y ddd
sudo apt install -y filezilla
sudo apt install -y gimp

# sudo apt install -y libaio1   # <- Needed for VMware Player & VMRC

# sudo apt install -y sqlitebrowser

# curl https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit

echo "Function: InstallDevelopmentTools completed"
}
# -------------------------------------------------------------------

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
function InstallGoogleChrome
{
echo "Function: InstallGoogleChrome"

# And the google chrome browser
cd ~/Downloads

wget ${CHROME_PACKAGE} --directory-prefix ~/Downloads
sudo dpkg -i ~/Downloads/${CHROME}
cd

echo "Function: InstallGoogleChrome completed"
}
# -------------------------------------------------------------------

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
function InstallAudioApplications
{
echo "Function: InstallAudioApplications"

sudo apt install -y brasero
sudo apt install -y sound-juicer
sudo apt install -y lame
sudo apt install -y easytag

echo "Function: InstallAudioApplications completed"
}
# -------------------------------------------------------------------


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# https://mintguide.org/musician/552-jack-audio-connection-kit-audio-server-for-linux.html
#
function InstallMusicApplications
{
echo "Function: InstallMusicApplications"

# NOTE: qjackctl requires permission to perform real time execution
#       Be sure to answer Yes.
sudo apt install -y qjackctl
sudo apt install -y audacity
sudo apt install -y lmms

# sudo apt install -y tuxguitar
# sudo apt install -y tuxguitar-jsa tuxguitar-alsa tuxguitar-fluidsynth

sudo wget ${TUX_GUITAR_INSTALLER} --directory-prefix ~/Downloads
sudo dpkg -i ~/Downloads/${TUX_GUITAR}; sudo apt-get -f install

echo "Function: InstallMusicApplications completed"
}
# -------------------------------------------------------------------


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
function SetGitUserPreferences
{
echo "Function: SetGitUserPreferences"

git config --global user.name "Steven Gomez"
git config --global user.email steve_gomez@usa.net

echo "Function: SetGitUserPreferences completed"
}
# -------------------------------------------------------------------

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
function FetchAndPrepareSlickEdit
{
echo "Function: FetchAndPrepareSlickEdit"

if [ ! -d "/opt/slickedit-pro2020" ]; then
    echo "Downloading & extracting SlickEdit package"
    sudo wget ${SLICKEDIT_INSTALLER} --directory-prefix /opt
    # sudo wget ${SLICKEDIT_KEY} --directory-prefix /opt
    cd /opt
    sudo tar -xvf ${SE_TAR}

    sudo rm ${SE_TAR}
    cd

else
    echo "SlickEdit directory appears to have previously been created (skipping)"
fi

# NOTE: After the script has run, perform the following steps to complete
#       SlickEdit installation
# cd se_${SE_VERSION}_linux64/
# sudo ./vsinst
# /opt/slickedit-pro2020/bin/vs &
# sudo mv SE_VLX818071_2300_Gomez.lic /opt/slickedit-pro2018/bin/slickedit.lic

echo "Function: FetchAndPrepareSlickEdit completed"
}
# -------------------------------------------------------------------


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
function UpdateEtcHostsEntries
{
echo "Function: UpdateEtcHostsEntries"

if grep -q esximgmt /etc/hosts; then
    echo "esximgmt entry already exists in /etc/hosts (skipping)"
else
    echo "Adding esximgmt to /etc/hosts"
    sudo echo '10.1.1.5     esximgmt  esximgmt.gomezengineering.lan   # ESXi Management' >> /etc/hosts
fi

if grep -q dionysus /etc/hosts; then
    echo "dionysus entry already exists in /etc/hosts (skipping)"
else
    echo "Adding dionysus to /etc/hosts"
    sudo echo '10.1.1.20     dionysus  dionysus.gomezengineering.lan   # Subversion 3343/csvn 18080/viewvc' >> /etc/hosts
fi

if grep -q teamcity /etc/hosts; then
    echo "teamcity entry already exists in /etc/hosts (skipping)"
else
    echo "Adding teamcity to /etc/hosts"
    sudo echo '10.1.1.21     teamcity  teamcity.gomezengineering.lan   # TeamCity 8111 ' >> /etc/hosts
fi

if grep -q hermes /etc/hosts; then
    echo "hermes entry already exists in /etc/hosts (skipping)"
else
    echo "Adding hermes to /etc/hosts"
    sudo echo '10.1.1.25     hermes  hermes.gomezengineering.lan   # External Web Server' >> /etc/hosts
fi

if grep -q devserver /etc/hosts; then
    echo "devserver entry already exists in /etc/hosts (skipping)"
else
    echo "Adding devserver to /etc/hosts"
    sudo echo '10.1.1.26     devserver  devserver.gomezengineering.lan   # Internal (Development) Web Server' >> /etc/hosts
fi

if grep -q minecraft /etc/hosts; then
    echo "minecraft entry already exists in /etc/hosts (skipping)"
else
    echo "Adding minecraft to /etc/hosts"
    sudo echo '10.1.1.31     minecraft  minecraft.gomezengineering.lan   # Minecraft server' >> /etc/hosts
fi

if grep -q sonarqube /etc/hosts; then
    echo "sonarqube entry already exists in /etc/hosts (skipping)"
else
    echo "Adding sonarqube to /etc/hosts"
    sudo echo '10.1.1.36     sonarqube  sonarqube.gomezengineering.lan   # Sonarqube 9000' >> /etc/hosts
fi

if grep -q porker /etc/hosts; then
    echo "porker entry already exists in /etc/hosts (skipping)"
else
    echo "Adding porker to /etc/hosts"
    sudo echo '10.1.1.45     porker  porker.gomezengineering.lan   # ReadyNAS' >> /etc/hosts
fi

if grep -q cardinalcam /etc/hosts; then
    echo "cardinalcam entry already exists in /etc/hosts (skipping)"
else
    echo "Adding cardinalcam to /etc/hosts"
    sudo echo '10.1.1.50     cardinalcam  cardinalcam.gomezengineering.lan   # Cardinal Cam ' >> /etc/hosts
fi

if grep -q ts7250b /etc/hosts; then
    echo "ts7250b entry already exists in /etc/hosts (skipping)"
else
    echo "Adding ts7250b to /etc/hosts"
    sudo echo '10.1.1.51     ts7250b  ts7250b.gomezengineering.lan   # TS7250 # 2 ' >> /etc/hosts
fi

if grep -q ts7252 /etc/hosts; then
    echo "ts7252 entry already exists in /etc/hosts (skipping)"
else
    echo "Adding ts7252 to /etc/hosts"
    sudo echo '10.1.1.52     ts7252  ts7252.gomezengineering.lan   # TS7252 Embedded Graphics' >> /etc/hosts
fi

if grep -q apollo /etc/hosts; then
    echo "apollo entry already exists in /etc/hosts (skipping)"
else
    echo "Adding apollo to /etc/hosts"
    sudo echo '10.1.1.70     apollo  apollo.gomezengineering.lan   # Logitech Squeezebox Server 9000' >> /etc/hosts
fi

echo "Function: UpdateEtcHostsEntries completed"
}
# -------------------------------------------------------------------


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
function FetchAndInstallVirtualizationPackages
{
echo "Function: FetchAndInstallVirtualizationPackages"

sudo wget ${VMRC_INSTALLER} --directory-prefix ~/Downloads
chmod +x ~/Downloads/${VMRC}

# sudo wget ${VMPLAYER_INSTALLER} --directory-prefix ~/Downloads
# sudo wget ${VMPLAYER_LICENSE} --directory-prefix ~/Downloads
# chmod +x ~/Downloads/${VMPLAYER}

# sudo sh ~/Downloads/${VMRC}
# sudo sh ~/Downloads/${VMPLAYER}

# Transitioning to VirtualBox due to processor limitations with VMplayer
sudo apt install -y libqt5opengl5 # <- Needed for VirtualBox 6.0
sudo wget ${VBOX_INSTALLER} --directory-prefix ~/Downloads
sudo dpkg -i ~/Downloads/${VIRTUAL_BOX}

echo "Function: FetchAndInstallVirtualizationPackages completed"
}
# -------------------------------------------------------------------


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
#
# Script execution starts below
#
#
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

echo "Starting script execution"
uname -a

# Abandoning these due to Mint Package manager issues on fresh install
# PerformUpdate
# PerformUpgrade

InstallDevelopmentTools
#InstallGoogleChrome
#InstallAudioApplications
#InstallMusicApplications
#SetGitUserPreferences

FetchAndPrepareSlickEdit
#UpdateEtcHostsEntries
#FetchAndInstallVirtualizationPackages

echo "Script execution complete"

