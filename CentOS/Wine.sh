
# From:
# https://tecadmin.net/install-wine-centos8/
#
# Also see the following link that includes an RPM for RHEL/CentOS 7 (lot of good work found here)
# https://harbottle.gitlab.io/wine32/
# 
# Or even here - includes source for a script that pulls from 7 repos instead of compiling
# https://www.systutorials.com/how-to-install-wine-32-bit-on-centos-8/

# According to theory after running this script, from a Linux desktop
# a 32 bit Windoze application can be run using:
# wine 'application.exe'

dnf clean all
dnf update

# Install basics
dnf -y groupinstall 'Development Tools'
dnf -y install libX11-devel zlib-devel libxcb-devel libxslt-devel libgcrypt-devel libxml2-devel gnutls-devel libpng-devel libjpeg-turbo-devel libtiff-devel gstreamer1-devel dbus-devel fontconfig-devel freetype-devel 

# Download Wine source (other examples shows using /usr/src, probably doesn't matter)
cd /opt

# wget https://dl.winehq.org/wine/source/5.x/wine-5.1.tar.xz
# tar -Jxf wine-5.1.tar.xz
# cd wine-5.1
wget https://dl.winehq.org/wine/source/5.x/wine-5.6.tar.xz
tar -Jxf wine-5.6.tar.xz
cd wine-5.6


# =======================================================
# Configure - enable only one of the following
# For 32 bit systems
./configure

# For 64 bit systems
# ./configure --enable-win64
# =======================================================

# Make and install
make
make install

# Display the version of wine just installed
wine --version      # 32 bit
# wine64 --version    # 64 bit


