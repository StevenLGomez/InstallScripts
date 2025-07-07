#!/usr/bin/env bash

##########################################################################
##########################################################################
# Is assummed that development tools have been previously installed on the
# system that the agent is being installed onto.
#
# Development tool installation is handled by a separate script
#
# NOTE that the password for agent_admin is not assigned by the script, 
# therefore it must be set manually by root to allow log in.
#

# As root, export this script from subversion, then make executable using:
# svn export https://10.17.20.6:18080/svn/EngineeringEnvironment/installScripts/C7_installBuildAgent.sh  ~/C7_installBuildAgent.sh
# chmod +x ~/C7_installBuildAgent.sh
#
# When exporting (above), be certain to select (p)ermanently (by pressing p when prompted)
# to allow subversion to run without requiring prompting during the script.

# Disable firewall to allow agent communication
service firewalld stop
systemctl disable firewalld

# Create user for the build agent
useradd agent_admin

mkdir /opt/BuildAgent
chown agent_admin:root /opt/BuildAgent
cd /opt/BuildAgent

# svn export https://10.17.20.6:18080/svn/EngineeringEnvironment/BuildAgent/buildAgent.zip
wget http://server-ip:8111/update/buildAgent.zip
unzip buildAgent.zip
rm buildAgent.zip
mv conf/buildAgent.dist.properties conf/buildAgent.properties

# Apply network information for TeamCity server
sed -i 's/serverUrl=http\:\/\/localhost\:8111/serverUrl=http\:\/\/10.1.1.21\:8111/g' conf/buildAgent.properties

# Apply a temporary Agent Name (will require changing by Administrator after initial config)
sed -i 's/name=/name=RogueAgent/g' conf/buildAgent.properties

chown -R agent_admin:agent_admin /opt/BuildAgent/*

# Make the agent executable, then start it (NOTE must run as agent_admin, NOT root)
chmod +x /opt/BuildAgent/bin/agent.sh
runuser agent_admin -c '/opt/BuildAgent/bin/agent.sh start'

# Configure automatic start of build agent at boot time
#svn export https://10.17.20.6:18080/svn/EngineeringEnvironment/BuildAgent/buildAgent  /etc/systemd/system/buildAgent.service
#chmod 755 /etc/systemd/system/buildAgent.service
#systemctl enable buildAgent

