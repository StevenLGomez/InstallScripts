git clone https://github.com/mkiol/dsnote

cd dsnote/fedora

# optionally install build dependencies
dnf install rpmdevtools autoconf automake boost-devel cmake git kf5-kdbusaddons-devel libarchive-devel libxdo-devel libXinerama-devel libxkbcommon-x11-devel libXtst-devel libtool meson openblas-devel patchelf pybind11-devel python3-devel python3-pybind11 qt5-linguist qt5-qtmultimedia-devel qt5-qtquickcontrols2-devel qt5-qtx11extras-devel rubberband-devel taglib-devel vulkan-headers

./make_rpm.sh

