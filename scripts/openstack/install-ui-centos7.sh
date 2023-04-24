#!/bin/sh

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   echo "Exiting."
   exit 1
fi

# configure network on minimal installations
# check existing devices
nmcli d
sleep 15

# configure
nmtui

# Install required packages
yum update -y
yum install -y perl net-tools make gcc kernel-devel openssh-server zsh vim screen git
