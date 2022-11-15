

# Script to assist setting up a Rocky system to use with Yocto projects.


# From Page 19 Listing 2-1 CentOS (Probably closer to Rocky configuration than Fedora
# texinfo was not found
# python replaced with python2 below - this implies that python needs to be linked to python2

yum install gawk make wget tar bzip2 gzip python2 unzip perl patch diffutils diffstat git cpp gcc gcc-c++ glibc-devel chrpath socat perl-Data-Dumper perl-Text-ParseWords perl-Thread-Queue SDL-devel xterm

ln -s /usr/bin/python2 /usr/bin/python

# Download yocto from it's home site
mkdir ~/yocto
cd ~/yocto
tar xvfj <poky>.tar.bz2

cd poky
source $PWD/oe-init-build-env build-test-01

# Edits to conf/local.conf
BB_NUMBER_THREADS ?= "2"                # Added this line
PARALLEL_MAKE ?= "-j 2"                 # Added this line

MACHINE ?= "qemux86"                    # Existed, uncommented
DL_DIR ?= "%(TOPDIR)/downloads"         # Existed, uncommented
SSTATE_DIR ?= "${TOPDIR}/sstate-cache"  # Existed, uncommented
TMPDIR = "${TOPDIR}/tmp"                # Existed, uncommented - book example has underscore

# Updated these to be "outside" of the build tree
DL_DIR ?= "%(HOME)/repositories/downloads"         # Yocto downloads, can be shared
SSTATE_DIR ?= "${HOME}/repositories/sstate-cache"  # Yocto shared state, can be shared

# Consider adding this to conserve disk space, deletes packages after the package has been built.
INHERIT += rm_work

# core-image-sato <- Creates rfs with UI for mobile devices.

bitbake core-image-sato                     # Downloads and builds

bitbake -c fetchall core-image-sato         # Downloads all sources without building
bitbake -k core-image-sato                  # Keep building if errors are encountered

Build attempt failed with python3 error :(


