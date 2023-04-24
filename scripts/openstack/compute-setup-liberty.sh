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

## NOVA
yum -y install openstack-nova-compute sysfsutils 

sed -i.liberty_orig "/^\[DEFAULT\]/a \
rpc_backend = rabbit\n\
auth_strategy = keystone\n\
my_ip = $THISHOST_IP\n\
network_api_class = nova.network.neutronv2.api.API\n\
security_group_api = neutron\n\
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver\n\
firewall_driver = nova.virt.firewall.NoopFirewallDriver" /etc/nova/nova.conf

sed -i "/^\[oslo_messaging_rabbit\]/a \
rabbit_host = $CONTROLLER_IP\n\
rabbit_userid = openstack\n\
rabbit_password = $SERVICE_PWD\n" /etc/nova/nova.conf

sed -i "/^\[keystone_authtoken\]/a \
auth_uri = http://$CONTROLLER_IP:5000\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
project_name = service\n\
username = nova\n\
password = $SERVICE_PWD\n" /etc/nova/nova.conf

sed -i "/^\[vnc\]/a \
enabled = True\n\
vncserver_listen = 0.0.0.0\n\
vncserver_proxyclient_address = \$my_ip\n\
novncproxy_base_url = http://$CONTROLLER_IP:6080/vnc_auto.html\n" /etc/nova/nova.conf

sed -i "/^\[glance\]/a \
host = $CONTROLLER_IP\n" /etc/nova/nova.conf

sed -i "/^\[oslo_concurrency\]/a \
lock_path = /var/lib/nova/tmp\n" /etc/nova/nova.conf

#if compute node is virtual - change virt_type to qemu
if [ $(egrep -c '(vmx|svm)' /proc/cpuinfo) == "0" ]; then
    sed -i "/^\[libvirt\]/a \
virt_type = qemu" /etc/nova/nova.conf
fi

systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

## NEUTRON
yum -y install openstack-neutron openstack-neutron-linuxbridge ebtables ipset

#edit /etc/neutron/neutron.conf
sed -i.liberty_orig 's/^[a-z]/#&/g' /etc/neutron/neutron.conf
sed -i "/^\[DEFAULT\]/a \
auth_strategy = keystone\n\
rpc_backend = rabbit\n" /etc/neutron/neutron.conf

sed -i 's/^connection/#connection/g' /etc/neutron/neutron.conf

sed -i "/^\[oslo_messaging_rabbit\]/a \
rabbit_host = $CONTROLLER_IP\n\
rabbit_userid = openstack\n\
rabbit_password = $SERVICE_PWD\n" /etc/neutron/neutron.conf

sed -i "/^\[keystone_authtoken\]/a \
auth_uri = http://$CONTROLLER_IP:5000\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
project_name = service\n\
username = neutron\n\
password = $SERVICE_PWD\n" /etc/neutron/neutron.conf

sed -i "/^\[oslo_concurrency\]/a \
lock_path = /var/lib/neutron/tmp\n" /etc/neutron/neutron.conf

#get management and public NIC infos
for i in $(/usr/bin/ls /sys/class/net); do
    if [ "$(cat /sys/class/net/$i/ifindex)" == '2' ]; then
        MGT_NIC=$i
    fi
    if [ "$(cat /sys/class/net/$i/ifindex)" == '3' ]; then
        PUB_NIC=$i
    fi
done

echo "MGT = $MGT_NIC / PUB = $PUB_NIC"

#edit /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i.liberty_orig "/^\[linux_bridge\]/a \
physical_interface_mappings = public:$PUB_NIC" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i "/^\[vxlan\]/a \
enable_vxlan = True\n\
local_ip = $THISHOST_IP\n\
l2_population = True\n" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i "/^\[agent\]/a \
prevent_arp_spoofing = True" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i "/^\[securitygroup\]/a \
enable_security_group = True\n\
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver\n" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

#configure nova to use neutron
sed -i "/^\[neutron\]/a \
url = http://$NETWORK_IP:9696\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
region_name = RegionOne\n\
project_name = service\n\
username = neutron\n\
password = $SERVICE_PWD\n" /etc/nova/nova.conf

systemctl restart openstack-nova-compute.service
systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service

#EOF
