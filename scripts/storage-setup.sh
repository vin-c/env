#!/bin/bash

source config

#install ntp
yum -y install ntp
systemctl enable ntpd.service
systemctl start ntpd.service

#openstack repos
yum -y install yum-plugin-priorities
yum -y install epel-release
yum -y install http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm
yum -y upgrade
#yum -y install openstack-selinux

#loosen things up
systemctl stop firewalld.service
systemctl disable firewalld.service
sed -i 's/enforcing/disabled/g' /etc/selinux/config
echo 0 > /sys/fs/selinux/enforce

echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
sysctl -p

#cinder storage node

#add filter to /etc/lvm/lvm.conf
sed -i "s/^    filter/#IH4V##\n    # filter/g" /etc/lvm/lvm.conf
sed -i 's;#IH4V##;    # Filter for current device and cinder volume\n    filter = [ "a/sdb/", "a/sda/", "r/.*/"];g' /etc/lvm/lvm.conf

pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb

yum -y install openstack-cinder targetcli python-oslo-db MySQL-python

sed -i.bak "/\[database\]/a connection = mysql://cinder:$SERVICE_PWD@$CONTROLLER_IP/cinder" /etc/cinder/cinder.conf
sed -i '0,/\[DEFAULT\]/s//\[DEFAULT\]\
rpc_backend = rabbit\
rabbit_host = '"$CONTROLLER_IP"'\
auth_strategy = keystone\
my_ip = '"$THISHOST_IP"'\
iscsi_helper = lioadm/' /etc/cinder/cinder.conf
sed -i "/\[keystone_authtoken\]/a \
auth_uri = http://$CONTROLLER_IP:5000/v2.0\n\
identity_uri = http://$CONTROLLER_IP:35357\n\
admin_tenant_name = service\n\
admin_user = cinder\n\
admin_password = $SERVICE_PWD" /etc/cinder/cinder.conf

systemctl enable openstack-cinder-volume.service target.service
systemctl start openstack-cinder-volume.service target.service

echo 'export OS_TENANT_NAME=admin' > creds
echo 'export OS_USERNAME=admin' >> creds
echo 'export OS_PASSWORD='"$ADMIN_PWD" >> creds
echo 'export OS_AUTH_URL=http://'"$CONTROLLER_IP"':35357/v2.0' >> creds
source creds
