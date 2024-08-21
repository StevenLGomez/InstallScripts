
#!/usr/bin/env bash

# TODO:
# 1.) Installation on Fedora 31 succeeded when installing "by hand", however
#     got error when starting up LyX "No textclass found".  This needs to
#     be investigated.
# 2.) This function was originally included in the InstallDevTools.sh script,
#     but because of the time required for this installation has been moved
#     into a dedicated script.  Installation on F31 is still experimental,
#     and optimizations remain (for example removing previous version).

##########################################################################
# Install the LaTeX document generation tool set
# https://www.systutorials.com/241660/how-to-install-tex-live-on-centos-7-linux/
#
# Information displayed when insallation is complete (after 6+ hours)
#
# Welcome to TeX Live!
#
# See /usr/local/texlive/2019/index.html for links to documentation.
# The TeX Live web site (https://tug.org/texlive/) contains any updates and
# corrections. TeX Live is a joint project of the TeX user groups around the
# world; please consider supporting it by joining the group best for you. The
# list of groups is available on the web at https://tug.org/usergroups.html.
# 
# Add /usr/local/texlive/2019/texmf-dist/doc/man to MANPATH.
# Add /usr/local/texlive/2019/texmf-dist/doc/info to INFOPATH.
# Most importantly, add /usr/local/texlive/2019/bin/x86_64-linux
# to your PATH for current and future sessions.
# Logfile: /usr/local/texlive/2019/install-tl.log
# 
# Windows installs may be possible with (try at your own risk)
# https://ctan.org/tex-archive/systems/windows/protext
# OR
# https://miktex.org/download   <= Installs minimal package set
#
# www.texstudio.org
# 
function InstallLaTeX
{
    # Uninstall old version first
    yum -y erase texlive texlive*
	
    # Install the LaTeX Lyx GUI Editor
    yum -y --enablerepo=epel install lyx

    # Install dependencies for LaTeX
    yum -y install perl-Digest-MD5

    LATEX_NAME=install-tl-unx.tar.gz
    LATEX_URL=${PACKAGE_SERVER_URL}/${LATEX_NAME}

    mkdir WorkingDir
    cd WorkingDir

    # Use wget to pull the Python package
    wget ${LATEX_URL}
    tar -xvf ${LATEX_NAME}
    cd install-tl*

    # The following will need some interaction because it asks for settings
    ./install-tl

    cd ..
    rm -Rf WorkingDir
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

InstallLatex

