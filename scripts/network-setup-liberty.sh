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

#openstack repos
yum -y install centos-release-openstack-liberty
yum -y upgrade

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

## NEUTRON

#install neutron (option 2 with l3-services)
yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge python-neutronclient ebtables ipset

#edit /etc/neutron/neutron.conf
sed -i.liberty_orig 's/^[a-z]/#[a-z]/g' /etc/neutron/neutron.conf
sed -i "/^\[database\]/a \
connection = mysql://neutron:$SERVICE_PWD@$CONTROLLER_IP/neutron\n" /etc/neutron/neutron.conf

sed -i "/^\[DEFAULT\]/a \
notify_nova_on_port_status_changes = True\n\
notify_nova_on_port_data_changes = True\n\
nova_url = http://$CONTROLLER_IP:8774/v2\n\
rpc_backend = rabbit\n\
auth_strategy = keystone\n\
core_plugin = ml2\n\
service_plugins = router\n\
allow_overlapping_ips = True\n" /etc/neutron/neutron.conf

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

sed -i "/^\[nova\]/a \
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
region_name = RegionOne\n\
project_name = service\n\
username = nova\n\
password = $SERVICE_PWD\n" /etc/neutron/neutron.conf

sed -i "/^\[oslo_concurrency\]/a \
lock_path = /var/lib/neutron/tmp\n" /etc/neutron/neutron.conf

#edit /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i.liberty_orig 's/^[a-z]/#[a-z]/g' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i "/^\[ml2\]/a \
type_drivers = flat,vlan,vxlan\n\
tenant_network_types = vxlan\n\
mechanism_drivers = linuxbridge,l2population\n\
extension_drivers = port_security\n" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "/^\[ml2_type_flat\]/a \
flat_networks = public\n" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "/^\[ml2_type_vxlan\]/a \
vni_ranges = 1:1000" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "/^\[securitygroup\]/a \
enable_ipset = True\n" /etc/neutron/plugins/ml2/ml2_conf.ini

#edit /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i.liberty_orig 's/^[a-z]/#[a-z]/g' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "/^\[linux_bridge\]/a \
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

#edit /etc/neutron/l3_agent.ini
sed -i.liberty_orig 's/^[a-z]/#[a-z]/g' /etc/neutron/l3_agent.ini
sed -i "/^\[DEFAULT\]/a \
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver\n\
external_network_bridge =\n" /etc/neutron/l3_agent.ini

#edit /etc/neutron/dhcp_agent.ini
sed -i.liberty_orig 's/^[a-z]/#[a-z]/g' /etc/neutron/dhcp_agent.ini
sed -i "/^\[DEFAULT\]/a \
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver\n\
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq\n\
dnsmasq_config_file = /etc/neutron/dnsmasq-neutron.conf\n\
enable_isolated_metadata = True\n" /etc/neutron/dhcp_agent.ini

#edit /etc/neutron/dnsmasq-neutron.conf
echo "dhcp-option-force=26,1450" > /etc/neutron/dnsmasq-neutron.conf

## METADATA Agent
#edit /etc/neutron/metadata_agent.ini
sed -i.liberty_orig 's/^[a-z]/#[a-z]/g' /etc/neutron/metadata_agent.ini
sed -i "/^\[DEFAULT\]/a \
nova_metadata_ip = $NETWORK_IP\n\
metadata_proxy_shared_secret = $META_PWD\n\
auth_uri = http://$CONTROLLER_IP:5000\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_region = RegionOne\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
project_name = service\n\
username = neutron\n\
password = $SERVICE_PWD\n" /etc/neutron/metadata_agent.ini

#finalize
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

systemctl enable neutron-server.service neutron-linuxbridge-agent.service \
    neutron-dhcp-agent.service neutron-metadata-agent.service neutron-l3-agent.service
systemctl start neutron-server.service neutron-linuxbridge-agent.service \
    neutron-dhcp-agent.service neutron-metadata-agent.service neutron-l3-agent.service

#EOF
