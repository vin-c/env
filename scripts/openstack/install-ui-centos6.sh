#!/bin/sh

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   echo "Exiting."
   exit 1
fi

if ( ! hostname -f | grep '\.' > /dev/null ); then
   echo "The hostname -f command does not return with a fully qualified hostname,";
   echo "however this is necessary for the UI to run properly.";
   echo "Please check your hostname configuration ! Exiting.";
   exit 1
fi

# Install required packages
yum install epel-release
yum install -y http://repository.egi.eu/sw/production/umd/3/sl6/x86_64/updates/umd-release-3.0.1-1.el6.noarch.rpm
yum update -y
yum install -y ca-policy-egi-core
yum install -y emi-ui

# Get the SBG config (vo.france-grilles.fr) and install it
wget -O /tmp/emi_ui.tgz http://www.grand-est.fr/resources/UI/emi_ui.tgz
tar -xzf /tmp/emi_ui.tgz --directory /tmp
cp -R /tmp/emi_ui/* /opt/glite/yaim/etc/

# Cleaning...
rm -rf /tmp/emi_ui.tgz /tmp/emi_ui/

# Set correct rights
chmod 600 /opt/glite/yaim/etc/site-info.def
chmod 700 /opt/glite/yaim/etc/

# Write the config
/opt/glite/yaim/bin/yaim -c -s /opt/glite/yaim/etc/site-info.def -n UI && echo "Done !" || echo "Error ! go manual..."

# Certificate (as USER not root !!)
#mkdir ~/.globus
#openssl pkcs12 -clcerts -nokeys -in  /mnt/hgfs/doc/Certs/VGJ-GRID2-FR.p12 -out ~/.globus/usercert.pem
#openssl pkcs12 -nocerts -in /mnt/hgfs/doc/Certs/VGJ-GRID2-FR.p12 -out userkey.pem
#chmod 400 ~/.globus/*.pem
#chmod 700 ~/.globus
