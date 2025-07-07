
# Installed on Ubuntu 24.04

# 4 CPUs
# 8 G RAM
# 150 G HD - Eager zeroed

# BIOS FW - Ubuntu struggles with UEFI

# Installed from ISO - Did not install extra 3rd party utilities

# CREATE USER mythtv

# sudo apt install -y git   # <<<--- Need to install git to be able to get this repository.

# MythTV version from: https://www.mythtv.org/wiki/Mythbuntu
#                      https://launchpad.net/~mythbuntu/+archive/ubuntu/35
MYTH_REPO_NAME=ppa:mythbuntu
MYTH_REPO_VERSION=35


function PerformUpdate
{
    sudo apt -y update
    sudo apt -y upgrade
}

function AddMythTvRepositories
{
    sudo add-apt-repository -y MYTH_REPO_NAME/MYTH_REPO_VERSION
    sudo apt -y update
}

function InstallMythTvBackEnd
{
    sudo apt install -y mythtv-backend-master
    sudo apt install -y mythplugins
}

function InstallMythTvFrontEnd
{
    sudo apt install -y mythtv-frontend
}

# From: https://www.mythtv.org/wiki/Mythbuntu_Control_Panel
function InstallMythbuntuControlPanel
{
    sudo add-apt-repository -y ppa:mythcp/mcp 
    sudo apt -y update
    sudo apt install -y mythbuntu-control-panel
}





# ====================================================================================
# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================



PerformUpdate
# AddMythTvRepositories
# InstallMythTvBackend
# InstallMythTvBackEnd

# InstallMythTvFrontEnd     # This one is optional


InstallMythbuntuControlPanel


