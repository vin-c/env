#!/bin/bash

source config

#install ntp/chrony
yum -y install chrony
systemctl enable chronyd.service
sed -i 's/^server/#server/g' /etc/chrony.conf
sed -i "s/^#server\ 0/server\ $CONTROLLER_IP\ iburst\n#server\ 0/g" /etc/chrony.conf
systemctl start chronyd.service

#loosen things up
systemctl stop firewalld.service
systemctl disable firewalld.service
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

#openstack repos
yum -y install centos-release-openstack-liberty
yum -y upgrade

## CINDER block storage service
yum -y install lvm2
systemctl enable lvm2-lvmetad.service
systemctl start lvm2-lvmetad.service

#add filter to /etc/lvm/lvm.conf
sed -i '/Configuration option devices\/global_filter/i\    # Filter for current device and cinder volume\n    filter = \[ \"a\/sda\/\", \"a\/sdb\/\", \"r\/.*\/\"\]\n' /etc/lvm/lvm.conf

#create pv/vg
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb

#install packages
yum -y install openstack-cinder targetcli python-oslo-policy

#edit /etc/cinder/cinder.conf
sed -i.liberty_orig "/^\[database\]/a \
connection = mysql://cinder:$SERVICE_PWD@$CONTROLLER_IP/cinder" /etc/cinder/cinder.conf

sed -i "/^\[DEFAULT\]/a \
rpc_backend = rabbit\n\
auth_strategy = keystone\n\
enabled_backends = lvm\n\
glance_host = $CONTROLLER_IP\n\
my_ip = $THISHOST_IP\n" /etc/cinder/cinder.conf

sed -i "/^\[oslo_messaging_rabbit\]/a \
rabbit_host = $CONTROLLER_IP\n\
rabbit_userid = openstack\n\
rabbit_password = $SERVICE_PWD\n" /etc/cinder/cinder.conf

sed -i "/^\[keystone_authtoken\]/a \
auth_uri = http://$CONTROLLER_IP:5000\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
project_name = service\n\
username = cinder\n\
password = $SERVICE_PWD\n" /etc/cinder/cinder.conf

sed -i "/^\[matchmaker_redis\]/i \
[lvm]\n\
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver\n\
volume_group = cinder-volumes\n\
iscsi_protocol = iscsi\n\
iscsi_helper = lioadm\n\n" /etc/cinder/cinder.conf

sed -i "/^\[oslo_concurrency\]/a \
lock_path = /var/lib/cinder/tmp\n" /etc/cinder/cinder.conf

systemctl enable openstack-cinder-volume.service target.service
systemctl start openstack-cinder-volume.service target.service

#EOF
