
#!/usr/bin/env bash

##########################################################################
# Install the repository surgeon tool (located by Ryan Danner) 
# 
# http://www.catb.org/esr/reposurgeon/ 
# Installation Instructions: https://gitlab.com/esr/reposurgeon/blob/master/INSTALL.adoc
# 
function InstallRepoSurgeon
{
# Install some necessary extras (golang installed separately due to slow download speeds)
# dnf install -y asciidoc pypy xmlto
dnf install -y asciidoctor subversion mercurial
dnf install -y golang

# Download the code
git clone https://gitlab.com/esr/reposurgeon.git /opt/reposurgeon

# Build it
cd /opt/reposurgeon
# make gosetup
make get
make

cd ~

# Make links to usr/bin 
ln -s /opt/reposurgeon/repotool /usr/bin/repotool 
ln -s /opt/reposurgeon/repocutter /usr/bin/repocutter 
ln -s /opt/reposurgeon/repomapper /usr/bin/repomapper 
ln -s /opt/reposurgeon/reposurgeon /usr/bin/reposurgeon
}
# ------------------------------------------------------------------------

# ====================================================================================
# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================

##########################################################################
# NOTE - First must stop PackageKit or you will hang forever since it requires
#        the yum proxy to have been set previously (which is not done until this 
#        script runs)
systemctl stop packagekit

InstallRepoSurgeon

