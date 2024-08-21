
# Script to install Myth TV on Xubuntu 18.04
#
# Starting point for installation can be found here:
# http://www.mythbuntu.org/home/news
#
# And much more detailed help from:
# https://forum.mythtv.org/viewtopic.php?f=36&t=3114#p15073
#
sudo apt-get update
sudo add-apt-repository ppa:mythbuntu/30
sudo apt install -y mythtv

sudo adduser $USER mythtv
mkdir -p $HOME/.mythtv
ln -s -f /etc/mythtv/config.xml ~/.mythtv/config.xml

# Reboot
shutdown -r now

# Then do the following:
#
# Again using a terminal session make sure mythtv-backend is not running, 
# go into mythtv-setup configure as desired (remember to set Security Pin 
# to 0000, otherwise frontends will not connect to backend), and then start mythtv-backend 
#
# sudo systemctl stop mythtv-backend
# mythtv-setup
# sudo systemctl start mythtv-backend

# Check status of mythtv-backend using:
# systemctl status mythtv-backend

# if if shows inactive (dead), try:
# sudo systemctl daemon-reload
# sudo systemctl start mythtv-backend

